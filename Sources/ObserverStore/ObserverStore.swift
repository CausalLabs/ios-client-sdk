//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

final class ObserverStore: ObserverStoreProtocol {
    private let queue: DispatchQueue
    private var store: [ObserverToken: ObserverStoreItem]
    private let tokenFactory: () -> ObserverToken

    init(tokenFactory: @escaping () -> ObserverToken = { UUID().uuidString }) {
        self.queue = DispatchQueue(label: "ObserverStore", attributes: .concurrent)
        self.store = [:]
        self.tokenFactory = tokenFactory
    }

    func add(item: ObserverStoreItem) -> ObserverToken {
        queue.sync(flags: .barrier) {
            let token = tokenFactory()
            store[token] = item
            return token
        }
    }

    func remove(token: ObserverToken) {
        queue.sync(flags: .barrier) {
            store[token] = nil
        }
    }

    func fetch(keys: [FeatureKey]) -> [ObserverHandler] {
        queue.sync {
            store.values
                .filter { keys.contains($0.featureKey) }
                .map(\.handler)
        }
    }
}
