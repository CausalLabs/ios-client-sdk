//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

extension Encodable {
    func encodeToJSONObject() throws -> JSONObject {
        let data = try JSONEncoder().encode(self)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as? JSONObject
        return jsonObject ?? [:]
    }
}

extension Decodable {
    static func decodeFromJSONObject(_ jsonObject: JSONObject) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: jsonObject)
        return try JSONDecoder().decode(Self.self, from: data)
    }
}
