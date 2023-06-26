//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// Describes a feature generated from the Causal SDK.
public protocol FeatureProtocol: AnyObject {
    /// The name of the feature.
    static var name: String { get }

    /// Uniquely identifies this feature.
    var id: FeatureId { get }

    /// Whether or not this feature is active.
    var isActive: Bool { get set }

    /// The impression ids associated with this feature.
    var impressionIds: [ImpressionId] { get set }

    /// Serializes the feature arguments to JSON.
    func args() throws -> JSONObject

    /// Updates the feature using the specified JSON.
    func updateFrom(json: JSONObject) throws

    /// Returns a copy of this feature with `newImpressionId`.
    func copy(newImpressionId: ImpressionId) -> Self
}

extension FeatureProtocol {
    var name: String {
        Self.name
    }
}
