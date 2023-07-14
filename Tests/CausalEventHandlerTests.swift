//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import LDSwiftEventSource
import XCTest

final class CausalEventHandlerTests: XCTestCase {

    func test_validMessage_callsMessageHandler() {
        let expectation = self.expectation(description: #function)

        let messageHandler: (SSEMessage) -> Void = { _ in
            expectation.fulfill()
        }

        let eventHandler = CausalEventHandler(messageHandler: messageHandler)

        eventHandler.onMessage(eventType: "hello", messageEvent: MessageEvent(data: "0"))

        self.waitForExpectations(timeout: 1)
    }

    func test_invalidMessage_doesNotCallMessageHandler() {
        let expectation = self.expectation(description: #function)
        expectation.isInverted = true

        let messageHandler: (SSEMessage) -> Void = { _ in
            expectation.fulfill()
        }

        let eventHandler = CausalEventHandler(messageHandler: messageHandler)

        eventHandler.onMessage(eventType: "invalid", messageEvent: MessageEvent(data: "0"))

        self.waitForExpectations(timeout: 1)
    }
}
