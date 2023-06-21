//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

final class URLRequestExtensionsTests: XCTestCase {

    func test_baseConfiguration() throws {
        let session = Session(deviceId: fakeDeviceId, userId: "some-user", required: 99, optional: "text")
        let request = try URLRequest(impressionServer: fakeImpressionServer, endpoint: .features, session: session)
        let headers = try XCTUnwrap(request.allHTTPHeaderFields)

        XCTAssertEqual(headers["User-Agent"], "Causal iOS Client")
        XCTAssertEqual(headers["Accept"], "application/json,text/plain")
        XCTAssertEqual(headers["Content-Type"], "application/json")
        XCTAssertEqual(headers["x-causal-deviceid"], fakeDeviceId)

        XCTAssertEqual(request.httpMethod, "POST")
    }

    func test_constructsValidURL_features() throws {
        let request = try URLRequest(impressionServer: fakeImpressionServer, endpoint: .features, session: FakeSession())
        let url = try XCTUnwrap(request.url)
        XCTAssertEqual(url.absoluteString, "https://tools.causallabs.io/sandbox-iserver/features")
    }

    func test_constructsValidURL_signal() throws {
        let request = try URLRequest(impressionServer: fakeImpressionServer, endpoint: .signal, session: FakeSession())
        let url = try XCTUnwrap(request.url)
        XCTAssertEqual(url.absoluteString, "https://tools.causallabs.io/sandbox-iserver/signal")
    }
}
