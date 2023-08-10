//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// Describes a feature generated from the Causal SDK.
public protocol FeatureProtocol: AnyObject {
    associatedtype Args: Codable, Hashable
    associatedtype Outputs: FeatureOutputsProtocol
    associatedtype Event: FeatureEventProvider

    /// The name of the feature.
    static var name: String { get }

    /// The arguments associated with this instance of the feature.
    var args: Args { get }

    /// Indicates the current status of the feature 
    var status: FeatureStatus<Outputs> { get }

    /// Uniquely identifies this feature.
    var id: FeatureId { get }

    /// Update the instance of this feature
    /// - Warning This method is intended for `CausalClient` use only.
    func update(request: FeatureUpdateRequest) throws

    /// Generates a `FeatureEventPayload` from the instance of the feature
    /// which will correctly associate the event with the feature's impression id.
    ///
    /// - Parameter event: The `Event` to signal
    /// - Returns: Payload object with the correct  `Event` and `ImpressionId` to use
    ///     when signaling. This will return `nil` if the feature has not been successfully
    ///     requested from the `CausalClient`.
    func event(_ event: Event) -> FeatureEventPayload?

    /// Returns a new instance of the feature copying over all necessary data.
    func clone() -> Self
}

extension FeatureProtocol {
    /// Helper instance method to expose the static feature name
    var name: String {
        Self.name
    }
}
