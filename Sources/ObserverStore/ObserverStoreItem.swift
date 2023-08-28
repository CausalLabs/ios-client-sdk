//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

struct ObserverStoreItem: Equatable {
    let featureKey: FeatureKey
    let handler: ObserverHandler

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.featureKey == rhs.featureKey
    }
}
