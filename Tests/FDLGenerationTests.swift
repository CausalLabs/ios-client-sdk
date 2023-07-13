//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import XCTest

final class FDLGenerationTests: XCTestCase {
    func test_session_SHOULD_generateStaticMethodsForSessionKey_deviceId() {
        let session = Session.fromDeviceId("device_id")
        XCTAssertEqual(session.deviceId, "device_id")
        XCTAssertNil(session.arrivalKey)
        XCTAssertNil(session.userId)
        XCTAssertNil(session.required)
        XCTAssertNil(session.optional)
        XCTAssertNil(session.withDefault)
    }

    func test_session_SHOULD_generateStaticMethodsForSessionKey_arrivalKey() {
        let session = Session.fromArrivalKey("arrival_key")
        XCTAssertEqual(session.arrivalKey, "arrival_key")
        XCTAssertNil(session.deviceId)
        XCTAssertNil(session.userId)
        XCTAssertNil(session.required)
        XCTAssertNil(session.optional)
        XCTAssertNil(session.withDefault)
    }
}
