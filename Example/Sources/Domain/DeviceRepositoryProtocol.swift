//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import CausalLabsSDK

/// Describes an object with can provide device information
protocol DeviceRepositoryProtocol {

    /// The persistent id for this device.
    var deviceId: DeviceId { get }
}
