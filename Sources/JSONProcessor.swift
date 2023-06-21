//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

public typealias JSONObject = [String: AnyHashable]

struct JSONProcessor {

    private let logger: Logger

    init(logger: Logger = .shared) {
        self.logger = logger
    }

    func encodeRequestFeatures(
        features: [any FeatureProtocol],
        session: any SessionProtocol,
        impressionId: ImpressionId?
    ) throws -> Data {
        var json = JSONObject()
        json["args"] = try session.args()
        json["impressionId"] = impressionId
        json["reqs"] = try features.map {
            var each = JSONObject()
            each[Self._nameKeyOrderedFirst] = $0.name
            each["args"] = try $0.args()
            return each
        }

        return try self._applyKeyOrderingHack(json: json)
    }

    func encodeSignalEvent(
        event: any EventProtocol,
        session: any SessionProtocol,
        impressionId: ImpressionId
    ) throws -> Data {
        var json = JSONObject()
        json["id"] = try session.keys()
        json["impressionId"] = impressionId
        json["feature"] = event.featureName
        json["event"] = event.name
        json["args"] = try event.serialized()
        return try json.data()
    }

    func encodeSignalCachedFeatures(
        features: [any FeatureProtocol],
        session: any SessionProtocol,
        impressionId: ImpressionId
    ) throws -> Data {
        var json = JSONObject()
        json["id"] = try session.keys()

        var featureImpressionJSON = JSONObject()
        features.forEach {
            var impressionJSON = ["newImpression": impressionId]
            if let oldImpression = $0.impressionIds.first {
                impressionJSON["impression"] = oldImpression
            }
            featureImpressionJSON[$0.name] = impressionJSON
        }
        json["impressions"] = featureImpressionJSON
        return try json.data()
    }

    func encodeKeepAlive(session: any SessionProtocol) throws -> Data {
        try session.keys().data()
    }

    // The server is order-dependent for the feature "name" key. It must come first.
    // Unfortunately, this implementation detail leaks into the client.
    private static let _nameKeyOrderedFirst = "aaa_name"

    private func _applyKeyOrderingHack(json: JSONObject) throws -> Data {
        var data = try json.data()
        var jsonString = String(decoding: data, as: UTF8.self)

        let findAndReplaceKeys = [Self._nameKeyOrderedFirst: "name"]
        for (key, value) in findAndReplaceKeys {
            jsonString = jsonString.replacingOccurrences(of: "\(key)", with: "\(value)")
        }

        if let finalData = jsonString.data(using: .utf8) {
            data = finalData
        } else {
            throw CausalError.json(json: jsonString, error: nil)
        }

        return data
    }

    func decode(data: Data) throws -> JSONObject {
        do {
            let json = try JSONSerialization.jsonObject(
                with: data,
                options: [.allowFragments]) as? JSONObject
            return json ?? JSONObject()
        } catch {
            throw CausalError.json(json: data.jsonString(), error: error)
        }
    }

    func decodeRequestFeatures(
        response: Data,
        features: [any FeatureProtocol],
        session: any SessionProtocol
    ) throws -> (any SessionProtocol, [any FeatureProtocol]) {
        let responseJSON = try self.decode(data: response)

        var updatedFeatures = features
        var updatedSession = session

        if let sessionJSON = responseJSON["session"] as? JSONObject {
            try updatedSession.updateFrom(json: sessionJSON)

            if let impressions = responseJSON["impressions"] as? [Any] {

                assert(impressions.count == features.count)
                if impressions.count != features.count {
                    // Mismatch on feature requests and impressions.
                    // This should not happen. If it does, return features with defaults.
                    self.logger.warning("Requested \(features.count) features, but received \(impressions.count) impressions.")
                    return (updatedSession, features)
                }

                for index in 0..<impressions.count {
                    let eachImpression = impressions[index]
                    var eachFeature = updatedFeatures[index]

                    if let impressionString = eachImpression as? String, impressionString == "OFF" {
                        eachFeature.isActive = false
                    } else if let impressionJSON = eachImpression as? JSONObject {
                        try eachFeature.updateFrom(json: impressionJSON)
                        eachFeature.isActive = true
                    } else {
                        self.logger.warning("Received unknown impression data: \(eachImpression)")
                    }
                    updatedFeatures[index] = eachFeature
                }
            }
        }
        return (updatedSession, updatedFeatures)
    }
}

extension JSONObject {
    func data() throws -> Data {
        try JSONSerialization.data(withJSONObject: self, options: [.sortedKeys, .prettyPrinted])
    }
}
