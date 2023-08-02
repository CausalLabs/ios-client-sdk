//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// The main entry point to the Causal iOS SDK.
public final class CausalClient {

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

    private var previousSessionId: SessionId?

    private let networkClient: Networking

    private let jsonProcessor: JSONProcessor

    private let featureCache: FeatureCache

    private let sessionTimer: SessionTimer

    private let logger: Logger

    private let sseClientFactory: SSEClientFactoryProtocol

    private var sseClient: SSEClientProtocol?

    init(networkClient: Networking = NetworkClient(),
         jsonProcessor: JSONProcessor = JSONProcessor(),
         featureCache: FeatureCache = .shared,
         sessionTimer: SessionTimer = SessionTimer(),
         sseClientFactory: SSEClientFactoryProtocol = SSEClientFactory(),
         logger: Logger = .shared
    ) {
        self.networkClient = networkClient
        self.jsonProcessor = jsonProcessor
        self.featureCache = featureCache
        self.sessionTimer = sessionTimer
        self.sseClientFactory = sseClientFactory
        self.logger = logger
    }

    // MARK: Core API

    /// Requests a set of features to be updated from the impression server and updates them in-place.
    ///
    /// If your project is using SwiftUI we encourage the usage of the compiler generated view models in
    /// addition to the `requestCacheFill()` method to request features from the impression service.
    /// However, If you wish to use the `CausalClient` directly then this method is recommended.
    ///
    /// > Note: The `features` instances contain the default values for all feature outputs. In the
    /// > case of an error the default values will still be available to render the feature to the screen.
    ///
    /// - Parameters:
    ///   - features: The features to request. Upon successful completion the `features` instances
    ///     will be updated in-place from the impression service data.
    ///   - impressionId: The impression id that matches the specific view of the requested features.
    ///     If no id is provided, one will be generated automatically.
    ///
    /// - Returns: A ``CausalError`` or an iOS SDK `Error`, if one occurred.
    @discardableResult
    public func requestFeatures(
        _ features: [any FeatureProtocol],
        impressionId: ImpressionId = .newId()
    ) async -> Error? {
        guard let session = try? _validateSession() else {
            return CausalError.missingSession
        }

        logger.info("""
        Requesting features...
        Features: \(features)
        Impression Id: \(impressionId)
        """)

        if await !featureCache.isEmpty {
            let cachedFeatures = await featureCache.fetch(all: features)
            if !cachedFeatures.isEmpty,
               // ensure we fetched all requested features from the cache
               cachedFeatures.count == features.count {

                let signalTask = Task {
                    try await _signalCachedFeatures(
                        cachedFeatures,
                        session: session,
                        impressionId: impressionId
                    )
                }

                logger.info("Hydrating from cached features with impression id: \(impressionId)")

                // Hydrate each of the input feature instances with the data (outputs & isActive)
                // from the cached value and update the impression id.
                do {
                    for (index, cachedFeature) in cachedFeatures.enumerated() {
                        let inputFeature = features[index]
                        try inputFeature.update(
                            outputJson: cachedFeature.outputs,
                            isActive: cachedFeature.isActive
                        )
                        inputFeature.impressionId = impressionId
                    }
                    try await signalTask.value
                    return nil
                } catch {
                    logger.error("requestFeatures error", error: error)
                    return error
                }
            }
        }

        let task = Task {
            let jsonData = try jsonProcessor.encodeRequestFeatures(
                features: features,
                session: session,
                impressionId: impressionId
            )

            let responseData = try await networkClient.sendRequest(
                baseURL: impressionServer,
                endpoint: .features,
                session: session,
                body: jsonData
            )

            let (updatedSession, updatedFeatures) = try jsonProcessor.decodeRequestFeatures(
                response: responseData,
                features: features,
                session: session,
                impressionId: impressionId
            )

            try await _updateSession(updatedSession, andSaveFeatures: updatedFeatures)
        }

        do {
            try await task.value
            return nil
        } catch {
            logger.error("requestFeatures error", error: error)
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
    ///                   If no id is provided, one will be generated automatically.
    ///
    /// - Returns: The updated feature from the server, or the default feature if there was an error.
    ///
    /// - Throws: A ``CausalError`` or an iOS SDK `Error`.
    @discardableResult
    public func requestFeature<T: FeatureProtocol>(
        _ feature: T,
        impressionId: ImpressionId = .newId()
    ) async -> Error? {
        await requestFeatures([feature], impressionId: impressionId)
    }

    /// Requests a set of features that will be cached for later use.
    ///
    /// - Parameters:
    ///   - features: The features to request.
    ///
    /// - Throws: A ``CausalError`` or an iOS SDK `Error`.
    public func requestCacheFill(features: [any FeatureProtocol]) async throws {
        let session = try _validateSession()

        logger.info("""
        Requesting cache fill...
        Features: \(features)
        """)

        let task = Task {
            let jsonData = try jsonProcessor.encodeRequestFeatures(
                features: features,
                session: session,
                impressionId: nil
            )

            let responseData = try await networkClient.sendRequest(
                baseURL: impressionServer,
                endpoint: .features,
                session: session,
                body: jsonData
            )

            let (updatedSession, updatedFeatures) = try jsonProcessor.decodeRequestFeatures(
                response: responseData,
                features: features,
                session: session,
                impressionId: nil
            )

            try await _updateSession(updatedSession, andSaveFeatures: updatedFeatures)
        }

        try await task.result.get()
    }

    /// An alternative to `signalAndWait()` that is "fire-and-forget" and ignores errors.
    ///
    /// Signals that the specified event occurred for an impression.
    ///
    /// - Parameters:
    ///   - event: The event that occurred.
    ///   - impressionId: The impression id that matches the specific view of the feature, or `nil` for a session event.
    public func signalEvent(_ event: any EventProtocol, impressionId: ImpressionId?) {
        Task {
            do {
                try await signalAndWait(event: event, impressionId: impressionId)
            } catch {
                logger.error("Signal and wait error", error: error)
            }
        }
    }

    /// Signals that the specified event occurred for an impression.
    ///
    /// - Parameters:
    ///   - event: The event that occurred.
    ///   - impressionId: The impression id that matches the specific view of the feature, or `nil` for a session event.
    ///
    /// - Throws: A ``CausalError`` or an iOS SDK `Error`.
    public func signalAndWait(
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

        try await task.result.get()
    }

    /// Signals a feature impression when reading features from the cache.
    private func _signalCachedFeatures(
        _ cachedItems: [FeatureCache.CacheItem],
        session: any SessionProtocol,
        impressionId: ImpressionId
    ) async throws {
        logger.info("""
        Signaling cached features...
        Features: \(cachedItems.map { $0.name })
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
    public func clearCache() async {
        logger.info("Emptying the feature cache")
        await featureCache.removeAll()
    }

    /// Begins listening for server sent events.
    public func startSSE() {
        sseClient?.start()
    }

    /// Ends listening for server sent events.
    public func stopSSE() {
        sseClient?.stop()
    }

    // MARK: Private

    private func _validateSession() throws -> any SessionProtocol {
        guard let session else {
            let error = CausalError.missingSession
            logger.error("CausalClient.shared.session is nil", error: error)
            throw error
        }
        return session
    }

    private func _clearCacheIfSessionExpiredOrKeepAlive() async {
        if sessionTimer.isExpired {
            logger.info("Session has expired. SessionId: \(session?.id ?? "nil")")
            await clearCache()
            sessionTimer.start()
        } else {
            sessionTimer.keepAlive()
        }
    }

    private func _updateSession(
        _ updatedSession: any SessionProtocol,
        andSaveFeatures updatedFeatures: [any FeatureProtocol]
    ) async throws {
        session = updatedSession

        // check expiration and clear cache *before* saving new features
        await _clearCacheIfSessionExpiredOrKeepAlive()
        try await featureCache.save(all: updatedFeatures)

        logger.info("Saved updated features: \(updatedFeatures)")
    }

    private func _reinitializeSSEClientIfNeeded() {
        guard let session = try? _validateSession() else {
            sseClient?.stop()
            sseClient = nil
            return
        }

        let isStarted = sseClient?.isStarted ?? false

        sseClient?.stop()

        sseClient = sseClientFactory.createClient(
            impressionServer: impressionServer,
            session: session) { [weak self] message in
                self?._handleSSE(message: message)
            }

        // client was initially running, so restart
        if isStarted {
            sseClient?.start()
        }
    }

    private func _handleSSE(message: SSEMessage) {
        switch message {
        case .flushCache:
            Task {
                await clearCache()
            }

        case .flushFeatures(let names):
            Task {
                await featureCache.removeAllWithNames(names)
            }

        case .hello:
            break
        }
    }
}
