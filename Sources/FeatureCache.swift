//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

@MainActor
final class FeatureCache {
    struct CacheItem {
        let name: String
        let impressionId: ImpressionId?
        let isActive: Bool
        let outputs: JSONObject
    }

    static let shared = FeatureCache()

    private var _storage = [FeatureId: CacheItem]()

    var isEmpty: Bool {
        _storage.isEmpty
    }

    var count: Int {
        _storage.count
    }

    // MARK: Membership

    func contains(_ feature: any FeatureProtocol) -> Bool {
        fetch(feature) != nil
    }

    // MARK: Fetching

    func fetch(_ feature: any FeatureProtocol) -> CacheItem? {
        _storage[feature.id]
    }

    func fetch(all: [any FeatureProtocol]) -> [CacheItem] {
        all.compactMap { fetch($0) }
    }

    // MARK: Saving

    func save(_ feature: any FeatureProtocol) throws {
        _storage[feature.id] = try feature.buildCacheItem()
    }

    func save(all: [any FeatureProtocol]) throws {
        try all.forEach { try save($0) }
    }

    // MARK: Removing

    func remove(_ feature: any FeatureProtocol) {
        _storage.removeValue(forKey: feature.id)
    }

    func removeAllWithNames(_ namesToRemove: Set<String>) {
        _storage = _storage.filter { _, value in
            !namesToRemove.contains(value.name)
        }
    }

    func removeAll() {
        _storage.removeAll()
    }
}

private extension FeatureProtocol {
    func buildCacheItem() throws -> FeatureCache.CacheItem {
        FeatureCache.CacheItem(
            name: name,
            impressionId: impressionId,
            isActive: isActive,
            outputs: try outputs()
        )
    }
}
