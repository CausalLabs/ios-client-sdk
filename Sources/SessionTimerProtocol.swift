//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

/// Describes an entity which can maintain a sessions lifecycle
protocol SessionTimerProtocol {

    /// Is the session expired?
    var isExpired: Bool { get }

    /// Start the session
    func start()

    /// Expire the session
    func invalidate()

    /// Extend the life of the session
    func keepAlive()
}
