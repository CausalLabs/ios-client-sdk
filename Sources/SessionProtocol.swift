//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// Represents a user session.
public protocol SessionProtocol: Hashable {
    /// Uniquely identifies the session.
    var id: SessionId { get }

    /// Uniquely identifies the current device.
    var persistentId: DeviceId? { get }

    /// Serializes the session keys to JSON.
    func keys() throws -> JSONObject

    /// Serializes the session arguments to JSON.
    func args() throws -> JSONObject

    /// Updates the session using the specified JSON.
    mutating func updateFrom(json: JSONObject) throws
}

extension SessionProtocol {
    func headers() throws -> [String: String] {
        let keys = try self.keys()
        var headers = [String: String]()
        for (_key, _val) in keys {
            let key = "x-causal-\(_key)".lowercased()
            headers[key] = _val as? String
        }
        return headers
    }
}
