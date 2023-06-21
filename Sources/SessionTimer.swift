//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

final class SessionTimer {
    /// Default duration is 30 min.
    var duration = TimeInterval(60 * 30)

    var isExpired: Bool {
        guard let startTime = self._lastTouched else {
            return true
        }
        let elapsedSeconds = Date.now().timeIntervalSince(startTime)
        return elapsedSeconds >= self.duration
    }

    private var _lastTouched: Date?

    func start() {
        self._lastTouched = Date.now()
    }

    func invalidate() {
        self._lastTouched = nil
    }

    func keepAlive() {
        self.start()
    }
}

extension Date {
    fileprivate static func now() -> Date {
        Date()
    }
}
