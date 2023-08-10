//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// Describes the public interface for the causal client
public protocol CausalClientProtocol {

    /// Enables or disables logs for debugging.
    ///
    /// - See also: ``DebugLogVerbosity``
    var debugLogging: DebugLogVerbosity { get set }

    /// A configuration object that defines behavior and policies for a URL session.
    /// This can be used to supply custom request timeout intervals, additional http headers, and other request configurations.
    var configuration: URLSessionConfiguration { get set }

    /// The URL for the impression server.
    var impressionServer: URL { get set }

    /// The current session.
    var session: (any SessionProtocol)? { get set }

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
    ///
    /// - Returns: A ``CausalError`` or an iOS SDK `Error`, if one occurred.
    @discardableResult
    func requestFeatures(_ features: [any FeatureProtocol], impressionId: ImpressionId) async -> Error?

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
    func requestFeature(_ feature: any FeatureProtocol, impressionId: ImpressionId) async -> Error?

    /// Requests a set of features that will be cached for later use.
    ///
    /// - Parameters:
    ///   - features: The features to request.
    ///
    /// - Throws: A ``CausalError`` or an iOS SDK `Error`.
    func requestCacheFill(features: [any FeatureProtocol]) async throws

    /// Signal a session event occurred to the impression service.
    ///
    /// An alternative to `signalAndWait(sessionEvent:)` that is "fire-and-forget" and ignores errors.
    ///
    /// - Parameter sessionEvent: The session event that occurred.
    func signal(sessionEvent: any SessionEvent)

    /// Signal a session event occurred to the impression service.
    ///
    /// - Parameter sessionEvent: The session event that occurred.
    func signalAndWait(sessionEvent: any SessionEvent) async throws

    /// Signal a feature event occurred to the impression service.
    ///
    /// An alternative to `signalAndWait(featureEvent:)` that is "fire-and-forget" and ignores errors.
    ///
    /// - Parameter featureEvent: The feature event and the corresponding impression id of the
    /// feature at the time that the event occurred.
    func signal(featureEvent: FeatureEventPayload?)

    /// Signal a feature event occurred to the impression service.
    ///
    /// - Parameter featureEvent: The feature event and the corresponding impression id of the
    /// feature at the time that the event occurred.
    func signalAndWait(featureEvent: FeatureEventPayload?) async throws

    /// Asynchronously instructs the server to keep the session alive.
    /// This indicates that the user is still active and the session should not expire.
    func keepAlive()

    /// Clears all locally cached features.
    ///
    /// - Warning: This should rarely be used and is primarily intended for debugging.
    func clearCache()

    /// Begins listening for server sent events.
    ///
    /// - Warning: This is primarily intended for feature debugging and QA purposes
    func startSSE()

    /// Ends listening for server sent events.
    ///
    /// - Warning: This is primarily intended for feature debugging and QA purposes
    func stopSSE()
}

public extension CausalClientProtocol {
    /// Requests a set of features to be updated from the impression server and updates them in-place.
    ///
    /// If your project is using SwiftUI we encourage the usage of the compiler generated view models in
    /// addition to the `requestCacheFill()` method to request features from the impression service.
    /// However, If you wish to use the `CausalClient` directly then this method is recommended.
    ///
    /// - Note:
    ///     - An impression id will be automatically generated and used when calling this method.
    ///     - In the event of an error the input `features` instance contains default values
    ///     and can be used to render the feature to the screen.
    ///
    /// - Parameters:
    ///   - features: The features to request. Upon successful completion the `features` instances
    ///     will be updated in-place from the impression service data.
    ///   - impressionId: The impression id that matches the specific view of the requested features.
    ///
    /// - Returns: A ``CausalError`` or an iOS SDK `Error`, if one occurred.
    @discardableResult
    func requestFeatures(_ features: [any FeatureProtocol]) async -> Error? {
        await requestFeatures(features, impressionId: .newId())
    }

    /// Requests a single feature to be updated from the impression server. The passed in `feature` will be updated in-place
    /// with the results from the impression service.
    ///
    /// - Note:
    ///     - An impression id will be automatically generated and used when calling this method.
    ///     - In the event of an error the input `feature` instance contains default values
    ///     and can be used to render the feature to the screen.
    ///
    /// - Parameters:
    ///   - feature: The feature to request. Upon successful completion the `feature` instance
    ///     will be updated in-place from the impression service data.
    ///
    /// - Returns: The updated feature from the server, or the default feature if there was an error.
    ///
    /// - Throws: A ``CausalError`` or an iOS SDK `Error`.
    @discardableResult
    func requestFeature(_ feature: any FeatureProtocol) async -> Error? {
        await requestFeature(feature, impressionId: .newId())
    }
}
