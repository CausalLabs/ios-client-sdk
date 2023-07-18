//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

final class RealServerTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()

        let url = URL(string: "http://localhost:3001/health")!
        let (_, response) = try await URLSession.shared.data(from: url)
        let httpResponse = try XCTUnwrap(response.httpResponse)
        XCTAssertFalse(httpResponse.isError)
    }

    func testSessionEvent() async throws {
        CausalClient.shared.impressionServer = URL(string: "http://localhost:3004/iserver")!
        let session = Session(deviceId: "sessionEvent", userId: "abc", required: 1)
        CausalClient.shared.session = session

        // need to construct a session before sending session events
        await CausalClient.shared.updateFeatures([])

        try await session.signalAndWaitAddToCart(productid: "123")
    }

    func testComplexFeature() async throws {
        CausalClient.shared.impressionServer = URL(string: "http://localhost:3004/iserver")!
        CausalClient.shared.session = Session(deviceId: "testComplexFeature", userId: "abc", required: 1  )

        let nestedIn = NestedObject(float1: 0.123, int1: 7)
        let obj1In = TopLevelObject(float1: 1.234, enum1: Color.PRIMARY, string1: "this is a test", int1: 7_890, nested1: nestedIn)
        let float1In = 1_234.5678
        let enum1In = Color.WARNING
        let string1In = "another string"
        let int1In = 1_234

        let test = Test(obj1: obj1In, float1: float1In, enum1: enum1In, string1: string1In, int1: int1In)
        let featuresIn: [any FeatureProtocol] = [test]

        // for the moment, success is just not throwing an error
        let featuresOut = try await CausalClient.shared.requestFeatures(features: featuresIn)

        XCTAssertEqual(featuresOut.count, 1)
        let testOut = featuresOut[0] as? Test

        XCTAssertNotNil(testOut)

        // Test args are still what we specified
        XCTAssertEqual(testOut?.obj1, obj1In)
        XCTAssertEqual(testOut?.float1, float1In)
        XCTAssertEqual(testOut?.enum1, enum1In)
        XCTAssertEqual(testOut?.string1, string1In)
        XCTAssertEqual(testOut?.int1, int1In)

        XCTAssertNil(testOut?.obj2)
        XCTAssertNotNil(testOut?.obj3)
        XCTAssertEqual(testOut?.obj3?.float1, 2.0)
        XCTAssertEqual(testOut?.obj3?.enum1, Color.SECONDARY)
        XCTAssertEqual(testOut?.obj3?.string1, "FOO")
        XCTAssertEqual(testOut?.obj3?.int1, 4)
        XCTAssertNil(testOut?.obj3?.int2)
        XCTAssertEqual(testOut?.obj3?.nested1.float1, 3.0)
        XCTAssertEqual(testOut?.obj3?.nested1.int1, 7)

        // Test all outputs
        XCTAssertEqual(testOut?.obj1Out.float1, 1.0)
        XCTAssertEqual(testOut?.obj1Out.enum1, Color.PRIMARY)
        XCTAssertEqual(testOut?.obj1Out.string1, "ABC")
        XCTAssertEqual(testOut?.obj1Out.int1, 1)
        XCTAssertNil(testOut?.obj1Out.int2)
        XCTAssertEqual(testOut?.obj1Out.nested1.float1, 11.0)
        XCTAssertEqual(testOut?.obj1Out.nested1.int1, -1)
        XCTAssertNil(testOut?.obj2Out)
        XCTAssertEqual(testOut?.float1Out, 1.0)
        XCTAssertNil(testOut?.float2Out)
        XCTAssertEqual(testOut?.enum1Out, Color.PRIMARY)
        XCTAssertNil(testOut?.enum2Out)
        XCTAssertEqual(testOut?.string1Out, "")
        XCTAssertNil(testOut?.string2Out)
        XCTAssertEqual(testOut?.int1Out, 0)
        XCTAssertNil(testOut?.int2Out)

        var objForSignal = obj1In
        objForSignal.float1 = 12

        testOut?.signalClick(obj1: objForSignal, obj2: objForSignal, float1: 1.0, float2: 2.0, enum1: Color.SECONDARY, enum2: nil, string1: "test", string2: nil, int1: 31, int2: nil)

        try await testOut?.signalAndWaitClick(obj1: objForSignal, obj2: objForSignal, float1: 1.0, float2: 2.0, enum1: Color.SECONDARY, enum2: nil, string1: "test", string2: nil, int1: 31, int2: nil)

        // call again, make sure signal impression goes through
        _ = try await CausalClient.shared.requestFeatures(features: featuresIn)
    }
}
