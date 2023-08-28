//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

extension FeatureCacheProtocol {
    /// Helper method to see if a `feature` has an entry in the cache
    /// - Parameter feature: The feature in question
    /// - Returns: `true` if the feature is present in the cache, `false` otherwise.
    func contains(_ feature: any FeatureProtocol) throws -> Bool {
        contains(key: try feature.key())
    }

    /// Helper method to fetch all `features` from the cache.
    /// - Parameter all: Array of all features we want from the cache.
    /// - Returns: Array of cache items if all requested features are present in the cache. Empty array otherwise.
    func fetch(all: [any FeatureProtocol]) throws -> [FeatureCacheItem] {
        let keys = try all.map { try $0.key() }
        return fetch(keys: keys)
    }
}
