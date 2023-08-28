//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

struct RequestFeaturesResponse: Equatable {
    let isDeviceRegistered: Bool
    let sessionJson: JSONObject
    let encodedFeatureStatuses: [EncodedFeatureStatus]
}
