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

    /// The URL for the impression server.
    @RequiredOnce(description: "impression server URL", resettable: true)
    public var impressionServer: URL

    @RequiredOnce(description: "session", resettable: true)
    public var session: any SessionProtocol

    private var previousSessionId: SessionId?

    private let networkClient: Networking

    private let jsonProcessor: JSONProcessor

    private let featureCache: FeatureCache

    private let sessionTimer: SessionTimer

    private let logger: Logger

    init(networkClient: Networking = NetworkClient(),
         jsonProcessor: JSONProcessor = JSONProcessor(),
         featureCache: FeatureCache = .shared,
         sessionTimer: SessionTimer = SessionTimer(),
         logger: Logger = .shared) {
        self.networkClient = networkClient
        self.jsonProcessor = jsonProcessor
        self.featureCache = featureCache
        self.sessionTimer = sessionTimer
        self.logger = logger
    }

    /// Requests a set of features to be updated from the impression server.
    ///
    /// - Parameters:
    ///   - features: The features to request.
    ///   - impressionId: The impression id that matches the specific view of the requested features.
    ///     If no id is provided, one will be generated automatically.
    ///
    /// - Returns: The updated features from the server.
    ///
    /// - Throws: A ``CausalError``.
    public func requestFeatures(
        features: [any FeatureProtocol],
        impressionId: ImpressionId = .newId()
    ) async throws -> [any FeatureProtocol] {
        await self._validateAndExtendSession()

        if await !self.featureCache.isEmpty {
            let cachedFeatures = await self.featureCache.fetch(all: features)
            if !cachedFeatures.isEmpty,
               // ensure we fetched all requested features from the cache
               cachedFeatures.count == features.count {

                _ = Task {
                    try await self._signalCachedFeatures(
                        features: cachedFeatures,
                        impressionId: impressionId
                    )
                }

                return cachedFeatures
            }
        }

        let task = Task {
            let jsonData = try self.jsonProcessor.encodeRequestFeatures(
                features: features,
                session: self.session,
                impressionId: impressionId
            )

            let responseData = try await self.networkClient.sendRequest(
                baseURL: self.impressionServer,
                endpoint: .features,
                session: self.session,
                body: jsonData
            )

            let (updatedSession, updatedFeatures) = try self.jsonProcessor.decodeRequestFeatures(
                response: responseData,
                features: features,
                session: self.session
            )

            await self._updateSession(new: updatedSession)

            await self.featureCache.save(all: updatedFeatures)

            return updatedFeatures
        }

        return try await task.result.get()
    }

    /// Requests a set of features that will be cached for later use.
    ///
    /// - Parameters:
    ///   - features: The features to request.
    ///
    /// - Throws: A ``CausalError``.
    public func requestCacheFill(features: [any FeatureProtocol]) async throws {
        await self._validateAndExtendSession()

        let featuresNotCached = await self.featureCache.filter(notIncluded: features)

        let task = Task {
            let jsonData = try self.jsonProcessor.encodeRequestFeatures(
                features: featuresNotCached,
                session: self.session,
                impressionId: nil
            )

            let responseData = try await self.networkClient.sendRequest(
                baseURL: self.impressionServer,
                endpoint: .features,
                session: self.session,
                body: jsonData
            )

            let (updatedSession, updatedFeatures) = try self.jsonProcessor.decodeRequestFeatures(
                response: responseData,
                features: featuresNotCached,
                session: self.session
            )

            await self._updateSession(new: updatedSession)

            await self.featureCache.save(all: updatedFeatures)
        }

        try await task.result.get()
    }

    /// Signals that the specified event occurred for an impression.
    ///
    /// - Parameters:
    ///   - event: The event that occurred.
    ///   - impressionId: The impression id that matches the specific view of the feature.
    ///
    /// - Throws: A ``CausalError``.
    public func signalEvent(
        event: any EventProtocol,
        impressionId: ImpressionId
    ) async throws {
        await self._validateAndExtendSession()

        let task = Task {
            let jsonData = try self.jsonProcessor.encodeSignalEvent(
                event: event,
                session: self.session,
                impressionId: impressionId
            )

            try await self.networkClient.sendRequest(
                baseURL: self.impressionServer,
                endpoint: .signal,
                session: self.session,
                body: jsonData
            )
        }

        try await task.result.get()
    }

    /// Signals a feature impression when reading features from the cache.
    private func _signalCachedFeatures(
        features: [any FeatureProtocol],
        impressionId: ImpressionId
    ) async throws {
        let task = Task {
            let jsonData = try self.jsonProcessor.encodeSignalCachedFeatures(
                features: features,
                session: self.session,
                impressionId: impressionId
            )

            try await self.networkClient.sendRequest(
                baseURL: self.impressionServer,
                endpoint: .signal,
                session: self.session,
                body: jsonData
            )
        }

        try await task.result.get()
    }

    /// Instructs the server to keep the session alive.
    /// This indicates that the user is still active and the session should not expire.
    ///
    /// - Throws: A ``CausalError``.
    public func keepAlive() async throws {
        await self._validateAndExtendSession()

        let task = Task {
            let jsonData = try self.jsonProcessor.encodeKeepAlive(session: self.session)

            try await self.networkClient.sendRequest(
                baseURL: self.impressionServer,
                endpoint: .signal,
                session: self.session,
                body: jsonData
            )
        }

        try await task.result.get()
    }

    /// Clears all locally cached features.
    ///
    /// - Warning: This should rarely be used and is primarily intended for debugging.
    public func clearCache() async {
        await self.featureCache.removeAll()
    }

    private func _updateSession(new updatedSession: any SessionProtocol) async {
        /// save old `session.id` for validation
        self.previousSessionId = self.session.id

        /// if `session` has been updated,
        /// we need to re-validate (thus, empty the cache) *before* filling the cache below.
        /// otherwise, on the next validation call, we will incorrectly empty the cache.
        if self.session.id != updatedSession.id {
            self.session = updatedSession
            await self._validateAndExtendSession()
        }
    }

    private func _validateAndExtendSession() async {
        /// if `session` has changed, invalidate
        if self.session.id != self.previousSessionId {
            self.sessionTimer.invalidate()
        }

        if self.sessionTimer.isExpired {
            await self.featureCache.removeAll()
            self.sessionTimer.start()
        } else {
            self.sessionTimer.keepAlive()
        }
    }
}

// MARK: Convenience APIs

extension CausalClient {
    /// Requests a set of features to be updated from the impression server and updates them in-place.
    ///
    /// - Parameters:
    ///   - features: The features to request.
    ///   - impressionId: The impression id that matches the specific view of the requested features.
    ///     If no id is provided, one will be generated automatically.
    ///
    /// - Throws: A ``CausalError``.
    public func updateFeatures(
        _ features: inout [any FeatureProtocol],
        impressionId: ImpressionId = .newId()
    ) async throws {
        do {
            let updated = try await self.requestFeatures(features: features, impressionId: impressionId)
            features = updated
        } catch {
            throw error
        }
    }

    /// Requests a single feature to be updated from the impression server.
    ///
    /// - Parameters:
    ///   - feature: The feature to request.
    ///   - impressionId: The impression id that matches the specific view of the requested feature.
    ///                   If no id is provided, one will be generated automatically.
    ///
    /// - Returns: The updated feature from the server, or the default if there was an error.
    ///
    /// - Throws: A ``CausalError``.
    public func requestFeature<T: FeatureProtocol>(
        feature: T,
        impressionId: ImpressionId
    ) async throws -> T {
        let result = try await self.requestFeatures(
            features: [feature],
            impressionId: impressionId
        )
        return (result.first as? T) ?? feature
    }
}
