//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK

final class MockObserverStore: ObserverStoreProtocol {
    struct Calls {
        var add: [ObserverStoreItem] = []
        var remove: [ObserverToken] = []
        var fetch: [[FeatureKey]] = []
    }

    struct Stubs {
        var add: (ObserverStoreItem) -> ObserverToken = { _ in "token" }
        var remove: (ObserverToken) -> Void = { _ in }
        var fetch: ([FeatureKey]) -> [ObserverHandler] = { _ in [] }
    }

    private(set) var calls: Calls
    var stubs: Stubs

    init() {
        calls = Calls()
        stubs = Stubs()
    }

    func add(item: ObserverStoreItem) -> ObserverToken {
        calls.add.append(item)
        return stubs.add(item)
    }

    func remove(token: ObserverToken) {
        calls.remove.append(token)
        stubs.remove(token)
    }

    func fetch(keys: [FeatureKey]) -> [ObserverHandler] {
        calls.fetch.append(keys)
        return stubs.fetch(keys)
    }
}
