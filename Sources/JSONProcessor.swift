//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// Describes a JSON object.
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
        impressionId: ImpressionId?
    ) throws -> Data {
        var json = JSONObject()
        json["id"] = try session.keys()
        if impressionId != nil {
            json["impressionId"] = impressionId
        }
        if event.featureName != "session" {
            json["feature"] = event.featureName
        }
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
            if let oldImpression = $0.impressionId {
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
        session: any SessionProtocol,
        impressionId: ImpressionId?
    ) throws -> (any SessionProtocol, [any FeatureProtocol]) {
        let responseJSON = try self.decode(data: response)

        guard let sessionJSON = responseJSON["session"] as? JSONObject else {
            throw CausalError.parseFailure(message: "Unable to locate `session` in the response.")
        }

        guard let impressions = responseJSON["impressions"] as? [Any] else {
            throw CausalError.parseFailure(message: "Unable to locate `impressions` in the response.")
        }

        guard impressions.count == features.count else {
            // Mismatch on feature requests and impressions.
            // This should not happen. If it does, return features with defaults.
            throw CausalError.parseFailure(message: "Requested \(features.count) features, but received \(impressions.count) impressions.")
        }

        var updatedFeatures = features
        var updatedSession = session
        try updatedSession.updateFrom(json: sessionJSON)

        for index in 0..<impressions.count {
            let eachImpression = impressions[index]
            let eachFeature = updatedFeatures[index]

            if let impressionString = eachImpression as? String, impressionString == "OFF" {
                eachFeature.isActive = false
            } else if let impressionJSON = eachImpression as? JSONObject {
                try eachFeature.update(outputJson: impressionJSON, isActive: true)

                // If an impression id is supplied then we should overwrite the feature
                // outputs _impressionId with that value. If we do not have an impression
                // id then this is being called as part of a cache fill and we should
                // retain the _impressionId data that is returned from the server.
                if impressionId != nil {
                    eachFeature.impressionId = impressionId
                }

            } else {
                throw CausalError.parseFailure(message: "Received unknown impression data: \(eachImpression)")
            }
            updatedFeatures[index] = eachFeature
        }
        return (updatedSession, updatedFeatures)
    }
}

extension JSONObject {
    func data() throws -> Data {
        try JSONSerialization.data(withJSONObject: self, options: [.sortedKeys, .prettyPrinted])
    }
}
