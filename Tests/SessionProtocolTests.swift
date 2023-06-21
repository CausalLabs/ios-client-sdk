//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

final class SessionProtocolTests: XCTestCase {

    func test_init() {
        let session = Session(deviceId: fakeDeviceId, required: 0)
        XCTAssertEqual(session.deviceId, fakeDeviceId)
    }

    func test_id() {
        let session = Session(deviceId: "xxx", required: 0)
        XCTAssertEqual(
            session.id,
            #"{"args":{"deviceId":"xxx","required":0},"name":"Session"}"#
        )
    }

    func test_args() throws {
        let session = Session(deviceId: fakeDeviceId, required: 0)
        XCTAssertEqual(
            try session.args(),
            [
                "deviceId": fakeDeviceId,
                "required": 0
            ]
        )
    }

    func test_keys() throws {
        let session = Session(deviceId: fakeDeviceId, required: 0)
        XCTAssertEqual(
            try session.keys(),
            [
                "deviceId": fakeDeviceId
            ]
        )
    }

    func test_updateFromJSON() throws {
        // TODO: add some outputs to the session
        var session = Session(deviceId: fakeDeviceId, required: 0)

        // Empty JSON should leave default values set
        try session.updateFrom(json: JSONObject())
        XCTAssertEqual(session.deviceId, fakeDeviceId)
    }
}
