//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// Describes a feature generated from the Causal SDK.
public protocol FeatureProtocol: Hashable, Codable {
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
    mutating func updateFrom(json: JSONObject) throws
}

extension FeatureProtocol {
    var name: String {
        Self.name
    }
}
