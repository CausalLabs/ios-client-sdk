//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

struct FeatureCacheItem: Equatable {
    let key: FeatureKey
    let status: EncodedFeatureStatus
}
