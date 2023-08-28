//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

protocol SSEClientProtocol: AnyObject {
    var isStarted: Bool { get }
    var impressionServer: URL { get }
    var persistentId: DeviceId? { get }

    func start()
    func stop()
}
