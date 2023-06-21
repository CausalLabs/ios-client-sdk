//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

final class CausalErrorTests: XCTestCase {

    func test_jsonError_description() {
        let error = CausalError.json(
            json: fakeJSON,
            error: FakeError.missingInfo
        )

        XCTAssertEqual(
            error.description,
            """
            CausalError:
            - json: { "status" : "ok" }
            - underlying error: missingInfo
            """
        )
    }

    func test_networkResponseError_description() {
        let error = CausalError.networkResponse(
            request: URLRequest(url: fakeImpressionServer),
            response: HTTPURLResponse(url: fakeImpressionServer,
                                      statusCode: 400,
                                      httpVersion: nil,
                                      headerFields: ["key": "value"])!,
            error: FakeError.missingInfo
        )

        XCTAssertEqual(
            error.description,
            """
            CausalError:
            - request: https://tools.causallabs.io/sandbox-iserver
            - status code: 400
            - response URL: https://tools.causallabs.io/sandbox-iserver
            - response headers: [AnyHashable("key"): value]
            - underlying error: missingInfo
            """
        )
    }
}
