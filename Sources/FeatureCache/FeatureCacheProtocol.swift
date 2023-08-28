//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

protocol FeatureCacheProtocol {
    var isEmpty: Bool { get }
    var count: Int { get }

    func contains(key: FeatureKey) -> Bool

    func fetch(key: FeatureKey) -> FeatureCacheItem?
    func fetch(keys: [FeatureKey]) -> [FeatureCacheItem]

    func save(item: FeatureCacheItem)
    func save(items: [FeatureCacheItem])

    @discardableResult
    func removeAll() -> [FeatureKey]

    @discardableResult
    func removeAll(named namesToRemove: Set<String>) -> [FeatureKey]
}
