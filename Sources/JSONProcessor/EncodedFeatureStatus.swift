//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

/// Details the different states of the parsed feature data from the impression service
enum EncodedFeatureStatus: Equatable {
    /// Indicates that the  feature is active (on)
    /// - Parameters:
    ///   - outputJson: the encoded Feature.Output object
    case on(outputsJson: JSONObject)
    // swiftlint:disable:previous identifier_name

    /// Indicates that the cached feature was inactive (off)
    case off
}
