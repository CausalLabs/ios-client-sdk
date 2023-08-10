//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

/// Describes the base structure of all Feature Output types.
public protocol FeatureOutputsProtocol: Codable, Hashable {

    /// Impression id associated with this feature.
    var _impressionId: ImpressionId? { get }

    /// Default output values
    static var defaultValues: Self { get }
}
