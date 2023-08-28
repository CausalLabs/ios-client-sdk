//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

/// Describes an storage mechanism for feature observers.
protocol ObserverStoreProtocol {
    /// Adds an observer item to the store
    /// - Parameter item: item to add to the store
    /// - Returns: token to remove the observer when it is no longer needed.
    func add(item: ObserverStoreItem) -> ObserverToken

    /// Removes an observer from the store
    /// - Parameter token: the token returned in the `add(item:)` call
    func remove(token: ObserverToken)

    /// Return all observers that match a set of `FeatureKey`s
    /// - Parameter keys: The feature keys for we should filter the observers by.
    /// - Returns: Array of `ObserverHandler`s that observer features matching the `keys`.
    func fetch(keys: [FeatureKey]) -> [ObserverHandler]
}
