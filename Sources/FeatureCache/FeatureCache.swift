//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

final class FeatureCache: FeatureCacheProtocol {
    private var store = [FeatureKey: EncodedFeatureStatus]()
    private let queue = DispatchQueue(label: "FeatureCache", attributes: .concurrent)

    init() {}

    /// Returns whether or not the cache is empty
    var isEmpty: Bool {
        queue.sync {
            store.isEmpty
        }
    }

    /// Returns the number of items in the cache
    var count: Int {
        queue.sync {
            store.count
        }
    }

    /// Does the cache contain an entry for the given `key`
    /// - Parameter key: Specific feature identifier
    /// - Returns: Returns `true` if the feature is in the cache `false` otherwise
    func contains(key: FeatureKey) -> Bool {
        queue.sync {
            store[key] != nil
        }
    }

    /// Retrieve a single item from the cache
    /// - Parameter key: Specific feature identifier
    /// - Returns: Returns the item if present or `nil` otherwise
    func fetch(key: FeatureKey) -> FeatureCacheItem? {
        queue.sync {
            guard let status = store[key] else { return nil }
            return FeatureCacheItem(key: key, status: status)
        }
    }

    /// Retrieve a collection of items from the cache
    /// - Parameter keys: Specific feature identifiers
    /// - Returns: Array of cache items if all `keys` are present in the cache.
    ///      If even a single key is missing from the cache an empty array will be returned.
    ///      Note: the order of the returned array may differ from the order of the input `keys`.
    func fetch(keys: [FeatureKey]) -> [FeatureCacheItem] {
        queue.sync {
            let found = keys.compactMap { key -> FeatureCacheItem? in
                guard let status = store[key] else { return nil }
                return FeatureCacheItem(key: key, status: status)
            }

            return found.count == keys.count ? found : []
        }
    }

    /// Add an item to the cache
    /// - Parameter item: Item to add
    func save(item: FeatureCacheItem) {
        queue.sync(flags: .barrier) {
            store[item.key] = item.status
        }
    }

    /// Add multiple items to the cache
    /// - Parameter items: Items to add
    func save(items: [FeatureCacheItem]) {
        queue.sync(flags: .barrier) {
            for item in items {
                store[item.key] = item.status
            }
        }
    }

    /// Remove all items in the cache with a `key.name` contained in the input `names`
    /// - Parameter namesToRemove: Names of features to remove from the cache.
    /// - Returns: List of `FeatureKey`s that were removed from the cache.
    @discardableResult
    func removeAll(named namesToRemove: Set<String>) -> [FeatureKey] {
        queue.sync(flags: .barrier) {
            var keep = [FeatureKey: EncodedFeatureStatus]()
            var discard = [FeatureKey]()

            for (key, value) in store {
                if namesToRemove.contains(key.name) {
                    discard.append(key)
                } else {
                    keep[key] = value
                }
            }

            store = keep
            return discard
        }
    }

    /// Remove all items from the cache.
    /// - Returns: List of `FeatureKey`s that were removed from the cache.
    @discardableResult
    func removeAll() -> [FeatureKey] {
        queue.sync(flags: .barrier) {
            let discard = Array(store.keys)
            store.removeAll()
            return discard
        }
    }
}
