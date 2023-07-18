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
    /// - Seealso: ``DebugLogVerbosity``
    public var debugLogging: DebugLogVerbosity {
        get {
            self.logger.verbosity
        }
        set {
            self.logger.verbosity = newValue
        }
    }

    /// A configuration object that defines behavior and policies for a URL session.
    public var configuration: URLSessionConfiguration {
        get {
            self.networkClient.configuration
        }
        set {
            self.networkClient.configuration = newValue
        }
    }

    /// The URL for the impression server.
    @RequiredOnce(description: "impression server URL", resettable: true)
    public var impressionServer: URL

    /// The current session.
    public var session: (any SessionProtocol)? {
        didSet {
            self.logger.info("Saving updated session: \(String(describing: self.session))")

            // if previously nil and setting to nil, ignore
            if self.session == nil && oldValue == nil {
                return
            }

            let newSessionId = self.session?.id ?? ""
            let oldSessionId = oldValue?.id ?? ""

            // session has been updated, need to invalidate (and thus empty cache)
            if newSessionId != oldSessionId {
                self.logger.info("New session has started. SessionId: \(newSessionId)")
                self.sessionTimer.invalidate()
                self._reinitializeSSEClientIfNeeded()
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

    /// Requests a set of features to be updated from the impression server.
    ///
    /// - Parameters:
    ///   - features: The features to request.
    ///   - impressionId: The impression id that matches the specific view of the requested features.
    ///     If no id is provided, one will be generated automatically.
    ///
    /// - Returns: The updated features from the server.
    ///
    /// - Throws: A ``CausalError`` or an iOS SDK `Error`.
    public func requestFeatures(
        features: [any FeatureProtocol],
        impressionId: ImpressionId = .newId()
    ) async throws -> [any FeatureProtocol] {
        let session = try self._validateSession()

        self.logger.info("""
        Requesting features...
        Features: \(features)
        Impression Id: \(impressionId)
        """)

        if await !self.featureCache.isEmpty {
            let cachedFeatures = await self.featureCache.fetch(all: features)
            if !cachedFeatures.isEmpty,
               // ensure we fetched all requested features from the cache
               cachedFeatures.count == features.count {

                _ = Task {
                    try await self._signalCachedFeatures(
                        cachedFeatures,
                        session: session,
                        impressionId: impressionId
                    )
                }

                self.logger.info("Returning cached features with impression id: \(impressionId)")

                return cachedFeatures.map { $0.copy(newImpressionId: impressionId) }
            }
        }

        let task = Task {
            let jsonData = try self.jsonProcessor.encodeRequestFeatures(
                features: features,
                session: session,
                impressionId: impressionId
            )

            let responseData = try await self.networkClient.sendRequest(
                baseURL: self.impressionServer,
                endpoint: .features,
                session: session,
                body: jsonData
            )

            let (updatedSession, updatedFeatures) = try self.jsonProcessor.decodeRequestFeatures(
                response: responseData,
                features: features,
                session: session
            )

            await self._updateSession(updatedSession, andSaveFeatures: updatedFeatures)

            return updatedFeatures
        }

        return try await task.result.get()
    }

    /// Requests a set of features that will be cached for later use.
    ///
    /// - Parameters:
    ///   - features: The features to request.
    ///
    /// - Throws: A ``CausalError`` or an iOS SDK `Error`.
    public func requestCacheFill(features: [any FeatureProtocol]) async throws {
        let session = try self._validateSession()

        let featuresNotCached = await self.featureCache.filter(notIncluded: features)

        self.logger.info("""
        Requesting cache fill...
        Features: \(featuresNotCached)
        """)

        let task = Task {
            let jsonData = try self.jsonProcessor.encodeRequestFeatures(
                features: featuresNotCached,
                session: session,
                impressionId: nil
            )

            let responseData = try await self.networkClient.sendRequest(
                baseURL: self.impressionServer,
                endpoint: .features,
                session: session,
                body: jsonData
            )

            let (updatedSession, updatedFeatures) = try self.jsonProcessor.decodeRequestFeatures(
                response: responseData,
                features: featuresNotCached,
                session: session
            )

            await self._updateSession(updatedSession, andSaveFeatures: updatedFeatures)
        }

        try await task.result.get()
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
        let session = try self._validateSession()

        self.logger.info("""
        Signaling event...
        Event: \(event.name)
        Impression id: \(impressionId ?? "-")
        """)

        let task = Task {
            let jsonData = try self.jsonProcessor.encodeSignalEvent(
                event: event,
                session: session,
                impressionId: impressionId
            )

            try await self.networkClient.sendRequest(
                baseURL: self.impressionServer,
                endpoint: .signal,
                session: session,
                body: jsonData
            )
        }

        try await task.result.get()
    }

    /// Signals a feature impression when reading features from the cache.
    private func _signalCachedFeatures(
        _ features: [any FeatureProtocol],
        session: any SessionProtocol,
        impressionId: ImpressionId
    ) async throws {
        self.logger.info("""
        Signaling cached features...
        Features: \(features.map { $0.name })
        Impression id: \(impressionId)
        """)

        let task = Task {
            let jsonData = try self.jsonProcessor.encodeSignalCachedFeatures(
                features: features,
                session: session,
                impressionId: impressionId
            )

            try await self.networkClient.sendRequest(
                baseURL: self.impressionServer,
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
        guard let session = try? self._validateSession() else {
            return
        }

        self.logger.info("Requesting session keep alive. Session id: \(session.id)")

        _ = Task {
            let jsonData = try self.jsonProcessor.encodeKeepAlive(session: session)

            try await self.networkClient.sendRequest(
                baseURL: self.impressionServer,
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
        self.logger.info("Emptying the feature cache")
        await self.featureCache.removeAll()
    }

    /// Begins listening for server sent events.
    public func startSSE() {
        self.sseClient?.start()
    }

    /// Ends listening for server sent events.
    public func stopSSE() {
        self.sseClient?.stop()
    }

    // MARK: Private

    private func _validateSession() throws -> any SessionProtocol {
        guard let session = self.session else {
            let error = CausalError.missingSession
            self.logger.error("CausalClient.shared.session is nil", error: error)
            throw error
        }
        return session
    }

    private func _clearCacheIfSessionExpiredOrKeepAlive() async {
        if self.sessionTimer.isExpired {
            self.logger.info("Session has expired. SessionId: \(self.session?.id ?? "nil")")
            await self.clearCache()
            self.sessionTimer.start()
        } else {
            self.sessionTimer.keepAlive()
        }
    }

    private func _updateSession(
        _ updatedSession: any SessionProtocol,
        andSaveFeatures updatedFeatures: [any FeatureProtocol]
    ) async {
        self.session = updatedSession

        // check expiration and clear cache *before* saving new features
        await self._clearCacheIfSessionExpiredOrKeepAlive()
        await self.featureCache.save(all: updatedFeatures)

        self.logger.info("Saved updated features: \(updatedFeatures)")
    }

    private func _reinitializeSSEClientIfNeeded() {
        guard let session = try? self._validateSession() else {
            self.sseClient?.stop()
            self.sseClient = nil
            return
        }

        let isStarted = self.sseClient?.isStarted ?? false

        self.sseClient?.stop()

        self.sseClient = self.sseClientFactory.createClient(
            impressionServer: self.impressionServer,
            session: session) { [weak self] message in
                self?._handleSSE(message: message)
            }

        // client was initially running, so restart
        if isStarted {
            self.sseClient?.start()
        }
    }

    private func _handleSSE(message: SSEMessage) {
        switch message {
        case .flushCache:
            Task {
                await self.clearCache()
            }

        case .flushFeatures(let names):
            Task {
                await self.featureCache.removeAllWithNames(names)
            }

        case .hello:
            break
        }
    }
}

// MARK: Convenience API

extension CausalClient {
    /// An alternative to `requestFeatures()` that is non-throwing and updates features in-place.
    ///
    /// Requests a set of features to be updated from the impression server and updates them in-place.
    ///
    /// - Parameters:
    ///   - features: The features to request.
    ///   - impressionId: The impression id that matches the specific view of the requested features.
    ///     If no id is provided, one will be generated automatically.
    ///
    /// - Returns: A ``CausalError`` or an iOS SDK `Error`, if one occurred.
    @discardableResult
    public func updateFeatures(
        _ features: [any FeatureProtocol],
        impressionId: ImpressionId = .newId()
    ) async -> Error? {
        do {
            _ = try await self.requestFeatures(features: features, impressionId: impressionId)
            return nil
        } catch {
            self.logger.error("Update features error", error: error)
            return error
        }
    }

    /// Requests a single feature to be updated from the impression server.
    ///
    /// - Parameters:
    ///   - feature: The feature to request.
    ///   - impressionId: The impression id that matches the specific view of the requested feature.
    ///                   If no id is provided, one will be generated automatically.
    ///
    /// - Returns: The updated feature from the server, or the default feature if there was an error.
    ///
    /// - Throws: A ``CausalError`` or an iOS SDK `Error`.
    public func requestFeature<T: FeatureProtocol>(
        feature: T,
        impressionId: ImpressionId = .newId()
    ) async throws -> T {
        let result = try await self.requestFeatures(
            features: [feature],
            impressionId: impressionId
        )
        return (result.first as? T) ?? feature
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
                try await self.signalAndWait(event: event, impressionId: impressionId)
            } catch {
                self.logger.error("Signal and wait error", error: error)
            }
        }
    }
}
