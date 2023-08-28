//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import CausalLabsSDK
import SwiftUI

/// EnvironmentKey detailing the persistent unique identifier for this device
struct DeviceIdKey: EnvironmentKey {
    static let defaultValue: DeviceId = .newId()
}

extension EnvironmentValues {
    /// Persistent unique identifier for this device
    var deviceId: DeviceId {
        get { self[DeviceIdKey.self] }
        set { self[DeviceIdKey.self] = newValue }
    }
}
