//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

final class FeatureCache {
    struct CacheItem: Equatable {

        /// Describes the status of the cached feature
        enum Status: Equatable {
            /// Indicates that the cached feature is active (on)
            /// - Parameters:
            ///   - outputJson: the encoded Feature.Output object
            ///   - cachedImpressionId: the impression id that is stored in the `outputJson`. This is
            ///     just a helper so we do not have to decode the output json to check the impression id.
            case on(outputsJson: JSONObject, cachedImpressionId: ImpressionId)
            // swiftlint:disable:previous identifier_name

            /// Indicates that the cached feature was inactive (off)
            case off
        }

        /// The static name of the feature.
        let name: String

        /// The status of the cached feature.
        let status: Status
    }

    /// Describes the error states that the FeatureCache can be in.
    enum FeatureCacheError: Error {
        /// Indicates that the feature being saved to the cache is not allowed to be cached.
        case invalidFeature
    }

    private var _storage = [FeatureId: CacheItem]()
    private let queue = DispatchQueue(label: "FeatureCache", attributes: .concurrent)

    init() {}

    var isEmpty: Bool {
        queue.sync {
            _storage.isEmpty
        }
    }

    var count: Int {
        queue.sync {
            _storage.count
        }
    }

    // MARK: Membership

    func contains(_ feature: any FeatureProtocol) -> Bool {
        queue.sync {
            _storage[feature.id] != nil
        }
    }

    // MARK: Fetching

    func fetch(_ feature: any FeatureProtocol) -> CacheItem? {
        queue.sync {
            _storage[feature.id]
        }
    }

    func fetch(all: [any FeatureProtocol]) -> [CacheItem] {
        queue.sync {
            all.compactMap { _storage[$0.id] }
        }
    }

    // MARK: Saving

    func save(_ feature: any FeatureProtocol) throws {
        try queue.sync(flags: .barrier) {
            _storage[feature.id] = try feature.buildCacheItem()
        }
    }

    func save(all: [any FeatureProtocol]) throws {
        var temp: [String: CacheItem] = [:]
        for feature in all {
            temp[feature.id] = try feature.buildCacheItem()
        }

        queue.sync(flags: .barrier) {
            for feature in all {
                _storage[feature.id] = temp[feature.id]
            }
        }
    }

    // MARK: Removing

    func remove(_ feature: any FeatureProtocol) {
        queue.sync(flags: .barrier) {
            _storage[feature.id] = nil
        }
    }

    func removeAllWithNames(_ namesToRemove: Set<String>) {
        queue.sync(flags: .barrier) {
            _storage = _storage.filter { _, value in
                !namesToRemove.contains(value.name)
            }
        }
    }

    func removeAll() {
        queue.sync(flags: .barrier) {
            _storage.removeAll()
        }
    }
}

private extension FeatureProtocol {
    func buildCacheItem() throws -> FeatureCache.CacheItem {
        switch status {
        case .off:
            return FeatureCache.CacheItem(name: name, status: .off)

        case let .on(outputs):
            guard let impressionId = outputs._impressionId else {
                throw FeatureCache.FeatureCacheError.invalidFeature
            }

            return FeatureCache.CacheItem(
                name: name,
                status: .on(outputsJson: try encodeObject(outputs), cachedImpressionId: impressionId)
            )

        case .unrequested:
            throw FeatureCache.FeatureCacheError.invalidFeature
        }
    }

    private func encodeObject<T: Encodable>(_ object: T) throws -> JSONObject {
        let data = try JSONEncoder().encode(object)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as? JSONObject
        return jsonObject ?? [:]
    }
}
