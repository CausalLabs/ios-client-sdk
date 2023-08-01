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
    var impressionId: ImpressionId? { get set }

    /// Serializes the feature arguments to JSON.
    func args() throws -> JSONObject

    /// Serializes the feature outputs to JSON.
    func outputs() throws -> JSONObject

    func update(outputJson: JSONObject, isActive: Bool) throws
}

extension FeatureProtocol {
    var name: String {
        Self.name
    }
}
