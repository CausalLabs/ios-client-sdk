//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import LDSwiftEventSource
import XCTest

final class EventSourceConfigTests: XCTestCase {

    func test_init() throws {
        let eventHandler = CausalEventHandler { _ in }
        let session = MockSession()

        let config = EventSource.Config(
            impressionServer: fakeImpressionServer,
            eventHandler: eventHandler,
            session: session
        )

        XCTAssertTrue(config.handler is CausalEventHandler)

        let persistentId = try XCTUnwrap(session.persistentId)
        XCTAssertEqual(
            config.url.absoluteString,
            "\(fakeImpressionServer)/\(CausalEndpoint.sse.rawValue)?id=\(persistentId)"
        )

        let sessionHeaders = try session.headers()
        sessionHeaders.forEach { key, value in
            XCTAssertEqual(config.headers[key], value)
        }

        URLRequest.defaultHeaders.forEach { key, value in
            XCTAssertEqual(config.headers[key], value)
        }
    }
}
