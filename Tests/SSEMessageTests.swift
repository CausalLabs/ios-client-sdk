//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import LDSwiftEventSource
import XCTest

final class SSEMessageTests: XCTestCase {

    let emptyEvent = MessageEvent(data: "0")

    let timestampData = "1689272889997"

    var timestamp: TimeInterval {
        TimeInterval(self.timestampData) ?? 0
    }

    func test_init_invalidEvent() {
        let message = SSEMessage(eventType: "invalid", messageEvent: self.emptyEvent)
        XCTAssertNil(message)
    }

    func test_init_flushCache() {
        let message = SSEMessage(
            eventType: "flushcache",
            messageEvent: MessageEvent(data: self.timestampData)
        )

        let expected = SSEMessage.flushCache(timestamp: self.timestamp)

        XCTAssertEqual(message, expected)
    }

    func test_init_flushFeatures() {
        let message = SSEMessage(
            eventType: "flushfeatures",
            messageEvent: MessageEvent(data: "one two three four five")
        )

        let expected = SSEMessage.flushFeatures(names: ["one", "two", "three", "four", "five"])

        XCTAssertEqual(message, expected)
    }

    func test_init_hello() {
        let message = SSEMessage(
            eventType: "hello",
            messageEvent: MessageEvent(data: self.timestampData)
        )

        let expected = SSEMessage.hello(timestamp: self.timestamp)

        XCTAssertEqual(message, expected)
    }

    func test_init_noTimestamp() {
        let message = SSEMessage(
            eventType: "hello",
            messageEvent: MessageEvent(data: "")
        )

        let expected = SSEMessage.hello(timestamp: 0)

        XCTAssertEqual(message, expected)
    }
}
