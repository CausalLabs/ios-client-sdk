//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

final class HTTPURLResponseExtensionsTests: XCTestCase {

    func test_isError_forSuccess() {
        XCTAssertFalse(HTTPURLResponse.fake(statusCode: 100).isError)

        XCTAssertFalse(HTTPURLResponse.fake(statusCode: 200).isError)

        XCTAssertFalse(HTTPURLResponse.fake(statusCode: 300).isError)

        XCTAssertFalse(HTTPURLResponse.fake(statusCode: 399).isError)
    }

    func test_isError_forFailure() {
        XCTAssertTrue(HTTPURLResponse.fake(statusCode: 400).isError)

        XCTAssertTrue(HTTPURLResponse.fake(statusCode: 500).isError)

        XCTAssertTrue(HTTPURLResponse.fake(statusCode: 599).isError)
    }

    func test_httpResponse() {
        XCTAssertNil(URLResponse().httpResponse)
        XCTAssertNotNil(HTTPURLResponse().httpResponse)
    }
}
