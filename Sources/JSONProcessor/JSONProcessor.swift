//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

struct JSONProcessor {

    private let logger: Logger

    init(logger: Logger = .shared) {
        self.logger = logger
    }

    /// Encode all of the request data necessary for fetching features from the impression service.
    /// - Parameters:
    ///   - sessionArgsJson: Session data in JSON format
    ///   - impressionId: The impression id for this request. Pass in `nil` when using this to pre-fill the cache.
    ///   - featureKeys: The features that we would like to request from the service.
    /// - Returns: Returns the feature request json as a `Data` type for use when making the request to the impression service.
    func encodeRequestFeatures(sessionArgsJson: JSONObject, impressionId: ImpressionId?, featureKeys: [FeatureKey]) throws -> Data {
        let featureNameKey = "1_\(UUID().uuidString)_name"
        let versionKey = "1_\(UUID().uuidString)_version"
        let findAndReplaceKeys = [
            featureNameKey: "name",
            versionKey: "version"
        ]

        var json = JSONObject()
        json[versionKey] = 2
        json["args"] = sessionArgsJson
        json["impressionId"] = impressionId
        json["reqs"] = featureKeys.map { key in
            var featureRequest = JSONObject()
            featureRequest[featureNameKey] = key.name
            featureRequest["args"] = key.argsJson
            return featureRequest
        }

        var jsonString = String(decoding: try json.data(), as: UTF8.self)
        for (key, value) in findAndReplaceKeys {
            jsonString = jsonString.replacingOccurrences(of: "\(key)", with: "\(value)")
        }

        guard let finalData = jsonString.data(using: .utf8) else {
            throw CausalError.json(json: jsonString, error: nil)
        }

        return finalData
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
        cachedItems: [FeatureCacheItem],
        session: any SessionProtocol,
        impressionId: ImpressionId
    ) throws -> Data {
        var json = JSONObject()
        json["id"] = try session.keys()

        var featureImpressionJSON = JSONObject()
        cachedItems.forEach { item in
            var impressionJSON = ["newImpression": impressionId]
            if let oldImpression = item.impressionId {
                impressionJSON["impression"] = oldImpression
            }
            featureImpressionJSON[item.key.name] = impressionJSON
        }
        json["impressions"] = featureImpressionJSON
        return try json.data()
    }

    func encodeKeepAlive(session: any SessionProtocol) throws -> Data {
        try session.keys().data()
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

    func decodeRequestFeatures(response: Data) throws -> RequestFeaturesResponse {
        let responseJSON = try self.decode(data: response)

        guard let sessionJson = responseJSON["session"] as? JSONObject else {
            throw CausalError.parseFailure(message: "Unable to locate `session` in the response.")
        }

        guard let rawImpressions = responseJSON["impressions"] as? [Any] else {
            throw CausalError.parseFailure(message: "Unable to locate `impressions` in the response.")
        }

        let impressions = try rawImpressions.map { impression -> EncodedFeatureStatus in
            if let impressionString = impression as? String, impressionString == "OFF" {
                return .off
            }

            if let outputsJson = impression as? JSONObject {
                return .on(outputsJson: outputsJson)
            }

            throw CausalError.parseFailure(message: "Received unknown impression data: \(impression)")
        }

        let isDeviceRegistered = responseJSON["registered"] as? Bool ?? false

        return RequestFeaturesResponse(isDeviceRegistered: isDeviceRegistered, sessionJson: sessionJson, encodedFeatureStatuses: impressions)
    }
}

private extension JSONObject {
    func data() throws -> Data {
        try JSONSerialization.data(withJSONObject: self, options: [.sortedKeys, .prettyPrinted])
    }
}

private extension FeatureCacheItem {
    var impressionId: ImpressionId? {
        switch status {
        case let .on(outputsJson):
             return outputsJson["_impressionId"] as? ImpressionId

        case .off:
            return nil
        }
    }
}
