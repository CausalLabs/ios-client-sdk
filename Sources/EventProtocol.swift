//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// Describes an event generated from the Causal SDK.
public protocol EventProtocol: Hashable, Codable {
    /// The name of the feature for which this event is associated.
    static var featureName: String { get }

    /// The name of the event.
    static var name: String { get }

    /// Serializes this event to JSON.
    func serialized() throws -> JSONObject
}

extension EventProtocol {
    var featureName: String {
        Self.featureName
    }

    var name: String {
        Self.name
    }
}
