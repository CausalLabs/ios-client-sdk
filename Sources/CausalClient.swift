//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// The main entry point to the Causal iOS SDK.
public final class CausalClient: CausalClientProtocol {

    /// The ``CausalClient`` shared instance.
    ///
    /// - Warning: You must set ``impressionServer`` and ``session`` before using.
    public static let shared = CausalClient()

    // MARK: Configuration

    /// Enables or disables logs for debugging.
    ///
    /// - See also: ``DebugLogVerbosity``
    public var debugLogging: DebugLogVerbosity {
        get {
            logger.verbosity
        }
        set {
            logger.verbosity = newValue
        }
    }

    /// A configuration object that defines behavior and policies for a URL session.
    /// This can be used to supply custom request timeout intervals, additional http headers, and other request configurations.
    public var configuration: URLSessionConfiguration {
        get {
            networkClient.configuration
        }
        set {
            networkClient.configuration = newValue
        }
    }

    /// The URL for the impression server.
    @RequiredOnce(description: "impression server URL", resettable: true)
    public var impressionServer: URL

    /// The current session.
    public var session: (any SessionProtocol)? {
        didSet {
            logger.info("Saving updated session: \(String(describing: session))")

            // if previously nil and setting to nil, ignore
            if session == nil && oldValue == nil {
                return
            }

            let newSessionId = session?.id ?? ""
            let oldSessionId = oldValue?.id ?? ""

            // session has been updated, need to invalidate (and thus empty cache)
            if newSessionId != oldSessionId {
                logger.info("New session has started. SessionId: \(newSessionId)")
                sessionTimer.invalidate()
                _reinitializeSSEClientIfNeeded()
            }
        }
    }

    private enum DeviceRegistration {
        case registered(deviceId: DeviceId)
        case unregistered
    }

    private let networkClient: Networking
    private let jsonProcessor: JSONProcessor
    private let featureCache: FeatureCacheProtocol
    private let sessionTimer: SessionTimerProtocol
    private let logger: Logger
    private let sseClientFactory: SSEClientFactoryProtocol
    private var sseClient: SSEClientProtocol?

    /// Store for SSE observers
    private let observerStore: ObserverStoreProtocol

    /// Is the device registered and able to receive SSE updates?
    private var deviceRegistration: DeviceRegistration = .unregistered

    /// Construct an instance of the `CausalClient` for use in your application.
    ///
    /// - Parameters:
    ///   - impressionServer: The URL for the impression server.
    ///   - session: The current session.
    public convenience init(impressionServer: URL, session: any SessionProtocol) {
        self.init(
            networkClient: NetworkClient(),
            jsonProcessor: JSONProcessor(),
            featureCache: FeatureCache(),
            sessionTimer: SessionTimer(),
            sseClientFactory: SSEClientFactory(),
            logger: .shared
        )
        self.impressionServer = impressionServer
        self.session = session
    }

    init(networkClient: Networking = NetworkClient(),
         jsonProcessor: JSONProcessor = JSONProcessor(),
         featureCache: FeatureCacheProtocol = FeatureCache(),
         sessionTimer: SessionTimerProtocol = SessionTimer(),
         sseClientFactory: SSEClientFactoryProtocol = SSEClientFactory(),
         observerStore: ObserverStoreProtocol = ObserverStore(),
         logger: Logger = .shared
    ) {
        self.networkClient = networkClient
        self.jsonProcessor = jsonProcessor
        self.featureCache = featureCache
        self.sessionTimer = sessionTimer
        self.sseClientFactory = sseClientFactory
        self.observerStore = observerStore
        self.logger = logger
    }

    // MARK: Core API

    /// Requests a set of features to be updated from the impression server and updates them in-place.
    ///
    /// If your project is using SwiftUI we encourage the usage of the compiler generated view models in
    /// addition to the `requestCacheFill()` method to request features from the impression service.
    /// However, If you wish to use the `CausalClient` directly then this method is recommended.
    ///
    /// - Note: In the event of an error the input `features` instance contains default values
    ///     and can be used to render the feature to the screen.
    ///
    /// - Parameters:
    ///   - features: The features to request. Upon successful completion the `features` instances
    ///     will be updated in-place from the impression service data.
    ///   - impressionId: The impression id that matches the specific view of the requested features.
    ///
    /// - Returns: A ``CausalError`` or an iOS SDK `Error`, if one occurred.
    @discardableResult
    public func requestFeatures(_ features: [any FeatureProtocol], impressionId: ImpressionId) async -> Error? {
        guard let session = try? _validateSession() else {
            return CausalError.missingSession
        }

        logger.info("""
        Requesting features...
        Features: \(features)
        Impression Id: \(impressionId)
        """)

        // Check the Cache first.
        do {
            let cachedFeatures = try featureCache.fetch(all: features)
            if !cachedFeatures.isEmpty {
                logger.info("Hydrating from cached features with impression id: \(impressionId)")

                // Hydrate each of the input feature instances with the data (outputs & isActive)
                // from the cached value and update the impression id.
                for (index, cachedFeature) in cachedFeatures.enumerated() {
                    let inputFeature = features[index]
                    try inputFeature.update(
                        request: cachedFeature.updateRequest(newImpressionId: impressionId)
                    )
                }

                // Defer the signal call to enable a quick return of cached data.
                defer {
                    Task {
                        do {
                            try await _signalCachedFeatures(
                                cachedFeatures,
                                session: session,
                                impressionId: impressionId
                            )
                        } catch {
                            logger.error("requestFeatures error", error: error)
                        }
                    }
                }

                return nil
            }
        } catch {
            logger.error("requestFeatures error", error: error)
            return error
        }

        // No cached items - fetch from network
        let task = Task {
            let jsonData = try jsonProcessor.encodeRequestFeatures(
                sessionArgsJson: try session.args(),
                impressionId: impressionId,
                featureKeys: try features.map { try $0.key() }
            )

            let responseData = try await networkClient.sendRequest(
                baseURL: impressionServer,
                endpoint: .features,
                session: session,
                body: jsonData
            )

            let response = try jsonProcessor.decodeRequestFeatures(response: responseData)
            guard response.encodedFeatureStatuses.count == features.count else {
                // Mismatch on feature requests and impressions.
                throw CausalError.parseFailure(message: "Requested \(features.count) features, but received \(response.encodedFeatureStatuses.count) impressions.")
            }

            try _processRequestFeaturesResponse(response: response)

            // Update the features in-place
            var cacheItems = [FeatureCacheItem]()
            for (index, feature) in features.enumerated() {
                let key = try feature.key()
                let impression = response.encodedFeatureStatuses[index]
                cacheItems.append(FeatureCacheItem(key: key, status: impression))
                // If an impression id is supplied then we should overwrite the feature
                // outputs _impressionId with that value. If we do not have an impression
                // id then this is being called as part of a cache fill and we should
                // retain the _impressionId data that is returned from the server.
                switch impression {
                case .off:
                    try feature.update(request: .off)

                case let .on(impressionJson):
                    try feature.update(request: .on(outputJson: impressionJson, impressionId: impressionId))
                }
            }

            // Add items to the feature cache
            featureCache.save(items: cacheItems)
        }

        do {
            try await task.value
            return nil
        } catch {
            logger.error("requestFeatures error", error: error)

            // In the case of an error update the features in-place with the default output values and return the error
            for feature in features {
                do {
                    try feature.update(request: .defaultStatus)
                } catch {
                    logger.error("requestFeatures: Failed to update feature (\(feature.name)) with a default status", error: error)
                }
            }

            return error
        }
    }

    /// Requests a single feature to be updated from the impression server. The passed in `feature` will be updated in-place
    /// with the results from the impression service.
    ///
    /// - Note: In the event of an error the input `feature` instance contains default values
    ///     and can be used to render the feature to the screen.
    ///
    /// - Parameters:
    ///   - feature: The feature to request. Upon successful completion the `feature` instance
    ///     will be updated in-place from the impression service data.
    ///   - impressionId: The impression id that matches the specific view of the requested feature.
    ///
    /// - Returns: The updated feature from the server, or the default feature if there was an error.
    ///
    /// - Throws: A ``CausalError`` or an iOS SDK `Error`.
    @discardableResult
    public func requestFeature(_ feature: any FeatureProtocol, impressionId: ImpressionId) async -> Error? {
        await requestFeatures([feature], impressionId: impressionId)
    }

    /// Requests a set of features that will be cached for later use.
    ///
    /// - Parameters:
    ///   - features: The features to request.
    ///
    /// - Throws: A ``CausalError`` or an iOS SDK `Error`.
    public func requestCacheFill(features: [any FeatureProtocol]) async throws {
        let featuresCopy = features.map { $0.clone() }

        let session = try _validateSession()

        logger.info("""
        Requesting cache fill...
        Features: \(featuresCopy)
        """)

        let task = Task {
            let jsonData = try jsonProcessor.encodeRequestFeatures(
                sessionArgsJson: try session.args(),
                impressionId: nil,
                featureKeys: try features.map { try $0.key() }
            )

            let responseData = try await networkClient.sendRequest(
                baseURL: impressionServer,
                endpoint: .features,
                session: session,
                body: jsonData
            )

            let response = try jsonProcessor.decodeRequestFeatures(response: responseData)
            guard response.encodedFeatureStatuses.count == features.count else {
                // Mismatch on feature requests and impressions.
                throw CausalError.parseFailure(message: "Requested \(features.count) features, but received \(response.encodedFeatureStatuses.count) impressions.")
            }

            // Update the session
            try _processRequestFeaturesResponse(response: response)

            // Save the items into the cache
            let cacheItems = try featuresCopy.enumerated().map { index, feature in
                let key = try feature.key()
                let impression = response.encodedFeatureStatuses[index]
                return FeatureCacheItem(key: key, status: impression)
            }
            featureCache.save(items: cacheItems)
        }

        try await task.value
    }

    /// Signal a session event occurred to the impression service.
    ///
    /// An alternative to `signalAndWait(sessionEvent:)` that is "fire-and-forget" and ignores errors.
    ///
    /// - Parameter sessionEvent: The session event that occurred.
    public func signal(sessionEvent: any SessionEvent) {
        _signal(event: sessionEvent, impressionId: nil)
    }

    /// Signal a session event occurred to the impression service.
    ///
    /// - Parameter sessionEvent: The session event that occurred.
    public func signalAndWait(sessionEvent: any SessionEvent) async throws {
        try await _signalAndWait(event: sessionEvent, impressionId: nil)
    }

    /// Signal a feature event occurred to the impression service.
    ///
    /// An alternative to `signalAndWait(featureEvent:)` that is "fire-and-forget" and ignores errors.
    ///
    /// - Parameter featureEvent: The feature event and the corresponding impression id of the
    /// feature at the time that the event occurred.
    public func signal(featureEvent: FeatureEventPayload?) {
        guard let featureEvent else { return }
        _signal(event: featureEvent.event, impressionId: featureEvent.impressionId)
    }

    /// Signal a feature event occurred to the impression service.
    ///
    /// - Parameter featureEvent: The feature event and the corresponding impression id of the
    /// feature at the time that the event occurred.
    public func signalAndWait(featureEvent: FeatureEventPayload?) async throws {
        guard let featureEvent else { return }
        try await _signalAndWait(event: featureEvent.event, impressionId: featureEvent.impressionId)
    }

    private func _signal(event: any EventProtocol, impressionId: ImpressionId?) {
        Task {
            do {
                try await _signalAndWait(event: event, impressionId: impressionId)
            } catch {
                logger.error("Signal and wait error", error: error)
            }
        }
    }

    private func _signalAndWait(
        event: any EventProtocol,
        impressionId: ImpressionId?
    ) async throws {
        let session = try _validateSession()

        logger.info("""
        Signaling event...
        Event: \(event.name)
        Impression id: \(impressionId ?? "-")
        """)

        let task = Task {
            let jsonData = try jsonProcessor.encodeSignalEvent(
                event: event,
                session: session,
                impressionId: impressionId
            )

            try await networkClient.sendRequest(
                baseURL: impressionServer,
                endpoint: .signal,
                session: session,
                body: jsonData
            )
        }

        do {
            try await task.result.get()
        } catch {
            // Receiving a 410 status code while performing a signal indicates that the session is expired.
            if case let .networkResponse(_, response, _) = error as? CausalError, response.statusCode == 410 {
                sessionTimer.invalidate()
            }

            throw error
        }
    }

    /// Signals a feature impression when reading features from the cache.
    private func _signalCachedFeatures(
        _ cachedItems: [FeatureCacheItem],
        session: any SessionProtocol,
        impressionId: ImpressionId
    ) async throws {
        logger.info("""
        Signaling cached features...
        Features: \(cachedItems.map { $0.key.name })
        Impression id: \(impressionId)
        """)

        let task = Task {
            let jsonData = try jsonProcessor.encodeSignalCachedFeatures(
                cachedItems: cachedItems,
                session: session,
                impressionId: impressionId
            )

            try await networkClient.sendRequest(
                baseURL: impressionServer,
                endpoint: .signal,
                session: session,
                body: jsonData
            )
        }

        try await task.result.get()
    }

    /// Asynchronously instructs the server to keep the session alive.
    /// This indicates that the user is still active and the session should not expire.
    public func keepAlive() {
        guard let session = try? _validateSession() else {
            return
        }

        logger.info("Requesting session keep alive. Session id: \(session.id)")

        _ = Task {
            let jsonData = try jsonProcessor.encodeKeepAlive(session: session)

            try await networkClient.sendRequest(
                baseURL: impressionServer,
                endpoint: .signal,
                session: session,
                body: jsonData
            )
        }
    }

    /// Clears all locally cached features.
    ///
    /// - Warning: This should rarely be used and is primarily intended for debugging.
    public func clearCache() {
        logger.info("Emptying the feature cache")
        featureCache.removeAll()
    }

    /// Add an observer for the feature. The `handler` callback will be triggered if a Server Sent
    /// Event (SSE) forces this feature's values to change. It is recommended to use the compiler
    /// generated `FeatureViewModel`s as those will wire up QA observers automatically and
    /// send impression events at the correct time.
    ///
    /// - Warning: Be sure to call the `removeObserver` method when your view disappears
    ///     or your reference object de-initializes to prevent memory leaks.
    ///
    /// - Parameters:
    ///   - feature: The feature instance to monitor for SSE updates.
    ///   - handler: Callback which will be called then the input `feature` is updated by a
    ///     Server Sent Event
    ///
    /// - Returns: An `ObserverToken` which can be used to remove the observer
    public func addObserver(feature: any FeatureProtocol, handler: @escaping () -> Void) throws -> ObserverToken {
        let token = observerStore.add(item: .init(featureKey: try feature.key(), handler: handler))
        logger.info("Adding observer for feature '\(feature.name)' with token '\(token)'")
        return token
    }

    /// Remove the Server Sent Event (SSE) observer.
    /// - Parameter observerToken: The `ObserverToken` returned when calling `addObserver`
    public func removeObserver(observerToken: ObserverToken) {
        logger.info("Removing observer with token '\(observerToken)'")
        observerStore.remove(token: observerToken)
    }

    // MARK: Private

    private func _validateSession() throws -> any SessionProtocol {
        guard let session else {
            let error = CausalError.missingSession
            logger.error("CausalClient.shared.session is nil", error: error)
            throw error
        }

        // If we have a session let's ensure that it is still valid
        if sessionTimer.isExpired {
            logger.info("Session has expired. Session Id: \(session.id)")
            clearCache()
            sessionTimer.start()
        } else {
            sessionTimer.keepAlive()
        }

        return session
    }

    private func _processRequestFeaturesResponse(response: RequestFeaturesResponse) throws {
        // Update the session arguments with the values in the response.
        try session?.updateFrom(json: response.sessionJson)

        if let persistentId = session?.persistentId, response.isDeviceRegistered {
            deviceRegistration = .registered(deviceId: persistentId)
        } else {
            deviceRegistration = .unregistered
        }

        // In some cases the
        _reinitializeSSEClientIfNeeded()
    }

    private func _reinitializeSSEClientIfNeeded() {
        guard let session = try? _validateSession() else {
            sseClient?.stop()
            sseClient = nil
            return
        }

        // Only re-initialize the SSEClient if the impressionServer or persistentId changed.
        guard case let .registered(registeredDeviceId) = deviceRegistration,
              sseClient?.impressionServer != impressionServer,
              sseClient?.persistentId != session.persistentId,
              sseClient?.persistentId != registeredDeviceId else {
            return
        }

        sseClient?.stop()

        sseClient = sseClientFactory.createClient(impressionServer: impressionServer, session: session) { [weak self] message in
            self?._processServerSentEvent(message: message)
        }

        sseClient?.start()
    }

    private func _processServerSentEvent(message: SSEMessage) {
        switch message {
        case .flushCache:
            Task {
                let discardedKeys = featureCache.removeAll()
                do {
                    try await _reloadCache(keys: discardedKeys)
                } catch {
                    logger.error("Error encountered while processing Server Sent Event", error: error)
                }
            }

        case .flushFeatures(let names):
            Task {
                let discardedKeys = featureCache.removeAll(named: names)
                do {
                    try await _reloadCache(keys: discardedKeys)
                } catch {
                    logger.error("Error encountered while processing Server Sent Event", error: error)
                }
            }

        case .hello:
            break
        }
    }

    private func _reloadCache(keys: [FeatureKey]) async throws {
        let session = try _validateSession()

        logger.info("""
        Requesting SSE cache update...
        Features: \(keys)
        """)

        let jsonData = try jsonProcessor.encodeRequestFeatures(
            sessionArgsJson: try session.args(),
            impressionId: nil,
            featureKeys: keys
        )

        let responseData = try await networkClient.sendRequest(
            baseURL: impressionServer,
            endpoint: .features,
            session: session,
            body: jsonData
        )

        let response = try jsonProcessor.decodeRequestFeatures(response: responseData)
        guard response.encodedFeatureStatuses.count == keys.count else {
            // Mismatch on feature requests and impressions.
            throw CausalError.parseFailure(message: "Requested \(keys.count) features, but received \(response.encodedFeatureStatuses.count) impressions.")
        }

        try _processRequestFeaturesResponse(response: response)

        // Save the items into the cache
        let cacheItems = keys.enumerated().map { index, key in
            let impression = response.encodedFeatureStatuses[index]
            return FeatureCacheItem(key: key, status: impression)
        }
        featureCache.save(items: cacheItems)

        // Run the handlers
        for observer in observerStore.fetch(keys: keys) {
            observer()
        }
    }
}

private extension FeatureCacheItem {
    func updateRequest(newImpressionId: ImpressionId) -> FeatureUpdateRequest {
        switch status {
        case .off:
            return .off

        case let .on(outputsJson):
            return .on(outputJson: outputsJson, impressionId: newImpressionId)
        }
    }
}
// swiftlint:disable:this file_length
