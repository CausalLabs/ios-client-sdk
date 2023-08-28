//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import CausalLabsSDK
import Foundation

final class DeviceRepository: DeviceRepositoryProtocol {
    private static let deviceIdKey = "com.causallabs.exampleApp.deviceId"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Returns the persistent id for this device which is stored in UserDefaults so that it
    /// will persist between application launches.
    var deviceId: DeviceId {
        guard let id = userDefaults.string(forKey: Self.deviceIdKey)  else {
            let id = DeviceId.newId()
            userDefaults.set(id, forKey: Self.deviceIdKey)
            return id
        }

        return id
    }
}
