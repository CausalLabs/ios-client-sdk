//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import Foundation
import XCTest

final class SessionTimerTests: XCTestCase {

    func test_initial_state() {
        let timer = SessionTimer()
        XCTAssertTrue(timer.isExpired)
    }

    func test_isExpired() {
        let timer1 = SessionTimer()
        timer1.start()
        XCTAssertFalse(timer1.isExpired)

        let timer2 = SessionTimer()
        timer2.duration = TimeInterval(2) // 2 seconds
        timer2.start()
        sleep(3)
        XCTAssertTrue(timer2.isExpired)
    }

    func test_invalidate() {
        let timer = SessionTimer()
        timer.start()
        XCTAssertFalse(timer.isExpired)

        timer.invalidate()
        XCTAssertTrue(timer.isExpired)
    }
}
