//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK

final class MockSessionTimer: SessionTimerProtocol {
    struct Calls {
        var start: [Void] = []
        var invalidate: [Void] = []
        var keepAlive: [Void] = []
    }

    struct Stubs {
        var start: () -> Void = {}
        var invalidate: () -> Void = {}
        var keepAlive: () -> Void = {}
    }

    private(set) var calls: Calls
    var stubs: Stubs

    init() {
        calls = Calls()
        stubs = Stubs()
    }

    var isExpired = false

    func start() {
        calls.start.append(())
        stubs.start()
    }

    func invalidate() {
        calls.invalidate.append(())
        stubs.invalidate()
    }

    func keepAlive() {
        calls.keepAlive.append(())
        stubs.keepAlive()
    }
}
