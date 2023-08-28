//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK

final class MockFeatureCache: FeatureCacheProtocol {
    struct Calls {
        var fetchKey: [FeatureKey] = []
        var fetchKeys: [[FeatureKey]] = []
        var contains: [FeatureKey] = []
        var saveItem: [FeatureCacheItem] = []
        var saveItems: [[FeatureCacheItem]] = []
        var removeAll: [Void] = []
        var removeAllNamed: [Set<String>] = []
    }

    struct Stubs {
        var fetchKey: (FeatureKey) -> FeatureCacheItem? = { _ in nil }
        var fetchKeys: ([FeatureKey]) -> [FeatureCacheItem] = { _ in [] }
        var contains: (FeatureKey) -> Bool = { _ in false }
        var saveItem: (FeatureCacheItem) -> Void = { _ in }
        var saveItems: ([FeatureCacheItem]) -> Void = { _ in }
        var removeAll: () -> [FeatureKey] = { [] }
        var removeAllNamed: (Set<String>) -> [FeatureKey] = { _ in [] }
    }

    private(set) var calls: Calls
    var stubs: Stubs

    var isEmpty = false
    var count: Int = 0

    init() {
        calls = Calls()
        stubs = Stubs()
    }

    func contains(key: FeatureKey) -> Bool {
        calls.contains.append(key)
        return stubs.contains(key)
    }

    func fetch(key: FeatureKey) -> FeatureCacheItem? {
        calls.fetchKey.append(key)
        return stubs.fetchKey(key)
    }

    func fetch(keys: [FeatureKey]) -> [FeatureCacheItem] {
        calls.fetchKeys.append(keys)
        return stubs.fetchKeys(keys)
    }

    func save(item: FeatureCacheItem) {
        calls.saveItem.append(item)
        stubs.saveItem(item)
    }

    func save(items: [FeatureCacheItem]) {
        calls.saveItems.append(items)
        stubs.saveItems(items)
    }

    func removeAll() -> [FeatureKey] {
        calls.removeAll.append(())
        return stubs.removeAll()
    }

    func removeAll(named namesToRemove: Set<String>) -> [FeatureKey] {
        calls.removeAllNamed.append(namesToRemove)
        return stubs.removeAllNamed(namesToRemove)
    }
}
