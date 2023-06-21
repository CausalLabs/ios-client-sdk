//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// Represents a user session.
public protocol SessionProtocol: Hashable {
    /// Uniquely identifies the session.
    var id: SessionId { get }

    /// Serializes the session keys to JSON.
    func keys() throws -> JSONObject

    /// Serializes the session arguments to JSON.
    func args() throws -> JSONObject

    /// Updates the session using the specified JSON.
    mutating func updateFrom(json: JSONObject) throws
}
