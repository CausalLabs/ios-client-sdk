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

    @MainActor
    func testCacheFill() async throws {
        let cache = FeatureCache()
        let client = CausalClient(featureCache: cache)
        client.debugLogging = .verbose

        let feature1 = RatingBox(productName: "name", productPrice: 3.0)
        let feature2 = ProductInfo()

        client.impressionServer = URL(string: "http://localhost:3004/iserver")!
        let session = Session(deviceId: "testCacheFill", userId: "abc", required: 1)
        client.session = session
        try await client.requestCacheFill(features: [feature1, feature2])

        // Ensure that the cache was updated
        XCTAssertEqual(cache.count, 2)
        XCTAssertTrue(cache.contains(feature1))
        XCTAssertTrue(cache.contains(feature2))

        // If the payload was successfully processed and hydrated then each
        // requested feature should hydrate the impression ids.
        XCTAssertNotNil(feature1.impressionId)
        XCTAssertNotNil(feature2.impressionId)

        // Pulling the features out of the cache should update the feature instances
        // with the new impressionId
        let newImpressionId = "testCacheFill - impression id"
        await client.requestFeatures([feature1, feature2], impressionId: newImpressionId)
        XCTAssertEqual(feature1.impressionId, newImpressionId)
        XCTAssertEqual(feature2.impressionId, newImpressionId)
    }

    func testSessionEvent() async throws {
        CausalClient.shared.impressionServer = URL(string: "http://localhost:3004/iserver")!
        let session = Session(deviceId: "testSessionEvent", userId: "abc", required: 1)
        CausalClient.shared.session = session

        // need to construct a session before sending session events
        await CausalClient.shared.requestFeatures([])

        try await session.signalAndWaitAddToCart(productid: "123")
    }

    func testImpressionIdFromCachedFeature() async throws {
        CausalClient.shared.impressionServer = URL(string: "http://localhost:3004/iserver")!
        let session = Session(deviceId: "testImpressionIdFromCachedFeature", userId: "abc", required: 1)
        CausalClient.shared.session = session

        // create a feature
        let feature1 = RatingBox(productName: "one", productPrice: 3.0)
        let id1 = "testImpressionIdFromCachedFeature - id1"
        let id2 = "testImpressionIdFromCachedFeature - id2"

        await CausalClient.shared.requestFeature(feature1, impressionId: id1)
        XCTAssertEqual(feature1.impressionId, id1)
        await CausalClient.shared.requestFeature(feature1, impressionId: id2)
        XCTAssertEqual(feature1.impressionId, id2)
    }

    @MainActor
    func test_requestFeatures_SHOULD_updateImpressionIdsWhenCalledMultipleTimes() async throws {
        let cache = FeatureCache()
        let client = CausalClient(featureCache: cache)
        client.impressionServer = URL(string: "http://localhost:3004/iserver")!
        let session = Session(deviceId: "test_requestFeatures_SHOULD_updateImpressionIdsWhenCalledMultipleTimes", userId: "abc", required: 1)
        client.session = session

        // create a feature
        let feature1 = RatingBox(productName: "one", productPrice: 3.0)
        let feature2 = RatingBox(productName: "one 2", productPrice: 3.0)
        let id1 = "test_requestFeatures_SHOULD_updateImpressionIdsWhenCalledMultipleTimes - id1"
        let id2 = "test_requestFeatures_SHOULD_updateImpressionIdsWhenCalledMultipleTimes - id2"

        await client.requestFeatures([feature1, feature2], impressionId: id1)

        XCTAssertEqual(feature1.impressionId, id1)
        XCTAssertEqual(feature2.impressionId, id1)

        await client.requestFeatures([feature1, feature2], impressionId: id2)

        XCTAssertEqual(feature1.impressionId, id2)
        XCTAssertEqual(feature2.impressionId, id2)
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
        let id: ImpressionId = "testComplexFeature - id"
        await CausalClient.shared.requestFeatures(featuresIn, impressionId: id)

        // Test args are still what we specified
        XCTAssertEqual(test.obj1, obj1In)
        XCTAssertEqual(test.float1, float1In)
        XCTAssertEqual(test.enum1, enum1In)
        XCTAssertEqual(test.string1, string1In)
        XCTAssertEqual(test.int1, int1In)

        XCTAssertNil(test.obj2)
        XCTAssertNotNil(test.obj3)
        XCTAssertEqual(test.obj3?.float1, 2.0)
        XCTAssertEqual(test.obj3?.enum1, Color.SECONDARY)
        XCTAssertEqual(test.obj3?.string1, "FOO")
        XCTAssertEqual(test.obj3?.int1, 4)
        XCTAssertNil(test.obj3?.int2)
        XCTAssertEqual(test.obj3?.nested1.float1, 3.0)
        XCTAssertEqual(test.obj3?.nested1.int1, 7)

        // Test all outputs
        XCTAssertEqual(test.obj1Out.float1, 1.0)
        XCTAssertEqual(test.obj1Out.enum1, Color.PRIMARY)
        XCTAssertEqual(test.obj1Out.string1, "ABC")
        XCTAssertEqual(test.obj1Out.int1, 1)
        XCTAssertNil(test.obj1Out.int2)
        XCTAssertEqual(test.obj1Out.nested1.float1, 11.0)
        XCTAssertEqual(test.obj1Out.nested1.int1, -1)
        XCTAssertNil(test.obj2Out)
        XCTAssertEqual(test.float1Out, 1.0)
        XCTAssertNil(test.float2Out)
        XCTAssertEqual(test.enum1Out, Color.PRIMARY)
        XCTAssertNil(test.enum2Out)
        XCTAssertEqual(test.string1Out, "")
        XCTAssertNil(test.string2Out)
        XCTAssertEqual(test.int1Out, 0)
        XCTAssertNil(test.int2Out)

        // Test the impression id was set correctly
        XCTAssertEqual(test.impressionId, id)

        var objForSignal = obj1In
        objForSignal.float1 = 12

        test.signalClick(obj1: objForSignal, obj2: objForSignal, float1: 1.0, float2: 2.0, enum1: Color.SECONDARY, enum2: nil, string1: "test", string2: nil, int1: 31, int2: nil)

        try await test.signalAndWaitClick(obj1: objForSignal, obj2: objForSignal, float1: 1.0, float2: 2.0, enum1: Color.SECONDARY, enum2: nil, string1: "test", string2: nil, int1: 31, int2: nil)

        // call again, make sure signal impression goes through
        _ = await CausalClient.shared.requestFeatures(featuresIn)
    }
}
