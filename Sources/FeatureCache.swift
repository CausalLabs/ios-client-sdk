//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

@MainActor
final class FeatureCache {
    static let shared = FeatureCache()

    private var _storage = [FeatureId: any FeatureProtocol]()

    var isEmpty: Bool {
        self._storage.isEmpty
    }

    var count: Int {
        self._storage.count
    }

    // MARK: Membership

    /// Returns all specified features that are *not* contained in the cache.
    func filter(notIncluded features: [any FeatureProtocol]) -> [any FeatureProtocol] {
        features.filter { !self.contains($0) }
    }

    func contains(_ feature: any FeatureProtocol) -> Bool {
        self.fetch(feature) != nil
    }

    // MARK: Fetching

    func fetch(_ feature: any FeatureProtocol) -> (any FeatureProtocol)? {
        self._storage[feature.id]
    }

    func fetch(all: [any FeatureProtocol]) -> [any FeatureProtocol] {
        all.compactMap { self.fetch($0) }
    }

    // MARK: Saving

    func save(_ feature: any FeatureProtocol) {
        self._storage[feature.id] = feature
    }

    func save(all: [any FeatureProtocol]) {
        all.forEach { self.save($0) }
    }

    // MARK: Removing

    func remove(_ feature: any FeatureProtocol) {
        self._storage.removeValue(forKey: feature.id)
    }

    func removeAllWithName(_ name: String) {
        let itemsToRemove = self._storage.filter { _, value in
            value.name == name
        }

        itemsToRemove.forEach { _, value in
            self.remove(value)
        }
    }

    func removeAll() {
        self._storage.removeAll()
    }
}
