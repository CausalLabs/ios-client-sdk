//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
// 

@testable import CausalLabsSDK
import XCTest

final class CausalClientTests: XCTestCase {
    func test_impressionServer() {
        CausalClient.shared.impressionServer = fakeImpressionServer
        XCTAssertNotNil(CausalClient.shared.impressionServer)

        let url = URL(string: "https://causallabs.io")!
        CausalClient.shared.impressionServer = url
        XCTAssertEqual(
            CausalClient.shared.impressionServer,
            url,
            "You should be able to reset the impression server URL"
        )
    }

    func test_session() {
        CausalClient.shared.session = MockSession()
        XCTAssertNotNil(CausalClient.shared.session)
    }

    func test_requestFeatures_hitsCorrectEndpoint() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let client = await CausalClient.fake(featureCache: .shared, mockNetworkingClient: mockNetworkingClient)

        _ = try await client.requestFeatures(
            features: [MockFeature()],
            impressionId: fakeImpressionId
        )

        XCTAssertEqual(mockNetworkingClient.receivedBaseURL, fakeImpressionServer)
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .features)
    }

    func test_requestFeatures_throwsErrorFromNetwork() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        mockNetworkingClient.stubbedError = CausalError.fakeNetwork()

        let client = await CausalClient.fake(
            featureCache: .shared,
            mockNetworkingClient: mockNetworkingClient
        )

        do {
            _ = try await client.requestFeatures(
                features: [RatingBox(productName: "name", productPrice: 10)],
                impressionId: fakeImpressionId
            )
            XCTFail("client should throw error from networking client")
        } catch {
            XCTAssertTrue(error is CausalError)
        }

        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled, "network client should be called")
    }

    func test_signalEvent_hitsCorrectEndpoint() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let client = await CausalClient.fake(
            featureCache: .shared,
            mockNetworkingClient: mockNetworkingClient
        )

        try await client.signalAndWait(
            event: MockEvent(),
            impressionId: fakeImpressionId
        )

        XCTAssertEqual(mockNetworkingClient.receivedBaseURL, fakeImpressionServer)
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .signal)
    }

    func test_signalEvent_throwsErrorFromNetwork() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        mockNetworkingClient.stubbedError = CausalError.fakeNetwork()

        let client = await CausalClient.fake(
            featureCache: .shared,
            mockNetworkingClient: mockNetworkingClient
        )

        do {
            try await client.signalAndWait(
                event: MockEvent(),
                impressionId: fakeImpressionId
            )
            XCTFail("client should throw error from networking client")
        } catch {
            XCTAssertTrue(error is CausalError)
        }

        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled, "network client should be called")
    }

    func test_keepAlive_hitsCorrectEndpoint() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let session = Session(deviceId: "id", required: 42)
        let client = await CausalClient.fake(
            featureCache: .shared,
            mockNetworkingClient: mockNetworkingClient,
            session: session
        )

        try await client.keepAlive()

        XCTAssertEqual(mockNetworkingClient.receivedBaseURL, fakeImpressionServer)
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .signal)

        XCTAssertEqual(mockNetworkingClient.receivedSession as? Session, session)
        XCTAssertEqual(mockNetworkingClient.receivedBody, try session.keys().data())
    }

    func test_clearCache() async throws {
        let cache = await FeatureCache()
        let client = CausalClient.fake(featureCache: cache)

        let features: [any FeatureProtocol] = [
            MockFeature(),
            RatingBox(productName: "name", productPrice: 10)
        ]

        // request cache fill
        try await client.requestCacheFill(features: features)
        let count = await cache.count
        XCTAssertEqual(count, 2)

        await client.clearCache()
        let isEmpty = await cache.isEmpty
        XCTAssertTrue(isEmpty)
    }

    func test_updateFeatures_updatesInPlace_andCachesUpdates() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        mockNetworkingClient.stubbedResponse = """
        {
            "session": {
                "deviceId": "8EB5B974-6BDF-44ED-8D1B-C1215C3B0FA3",
                "sessionId": "f45f7661-c338-4d24-9f00-1b02c3cf68f7",
                "startTime": 1687298716527
            },
            "impressions": [
                {
                    "product": "name",
                    "productPrice": 42,
                    "impressionIds": [
                        "E6C12889-B529-46C9-9C7A-1FBAD5AFF840"
                    ],
                    "impressions": [
                        {
                            "impressionId": "E6C12889-B529-46C9-9C7A-1FBAD5AFF840",
                            "impressionTime": 1687298716527
                        }
                    ],
                    "callToAction": "Different Call To Action",
                    "actionButton": "Different Action Button"
                }
            ]
        }
        """

        let cache = await FeatureCache()
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient
        )

        let feature = RatingBox(productName: "name", productPrice: 42)
        XCTAssertEqual(feature.callToAction, "Rate this product!")
        XCTAssertEqual(feature.actionButton, "Send Review")

        let isEmpty = await cache.isEmpty
        XCTAssertTrue(isEmpty)

        let error = await client.updateFeatures([feature], impressionId: fakeImpressionId)
        XCTAssertNil(error)

        XCTAssertEqual(feature.productName, "name")
        XCTAssertEqual(feature.productPrice, 42)
        XCTAssertEqual(feature.callToAction, "Different Call To Action")
        XCTAssertEqual(feature.actionButton, "Different Action Button")

        // Verify cache saved feature
        let count = await cache.count
        XCTAssertEqual(count, 1)

        let contains = await cache.contains(feature)
        XCTAssertTrue(contains)
    }

    func test_requestFeatures_withEmptyCache_savesToCache() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let cache = await FeatureCache()
        let timer = SessionTimer()
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient,
            sessionTimer: timer
        )

        let features: [any FeatureProtocol] = [
            MockFeature(),
            RatingBox(productName: "name", productPrice: 10)
        ]

        var isEmpty = await cache.isEmpty
        XCTAssertTrue(isEmpty)
        XCTAssertTrue(timer.isExpired)

        _ = try await client.requestFeatures(
            features: features,
            impressionId: fakeImpressionId
        )

        // Verify NetworkClient was called
        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled)

        // Verify cache saved features
        isEmpty = await cache.isEmpty
        XCTAssertFalse(isEmpty)

        let count = await cache.count
        XCTAssertEqual(count, 2)

        // Verify session is valid
        XCTAssertFalse(timer.isExpired)
    }

    func test_requestFeatures_withFullCache_fetchesFromCache() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let cache = await FeatureCache()
        let timer = SessionTimer()
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient,
            sessionTimer: timer
        )

        let initialImpressionId = String.newId()

        let feature1 = MockFeature()
        feature1.impressionIds = [initialImpressionId]

        let feature2 = RatingBox(productName: "name", productPrice: 10)
        feature2.impressionIds = [initialImpressionId]

        let features: [any FeatureProtocol] = [feature1, feature2]

        // request cache fill
        try await client.requestCacheFill(features: features)
        XCTAssertEqual(mockNetworkingClient.sendRequestCallCount, 1, "should hit network to fill cache")
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .features, "should hit features endpoint")

        let isEmpty = await cache.isEmpty
        XCTAssertFalse(isEmpty)

        let count = await cache.count
        XCTAssertEqual(count, 2)

        // request same features
        let requestedFeatures = try await client.requestFeatures(
            features: features,
            impressionId: fakeImpressionId
        )

        // we asynchronously signal cached features
        // thus, sleep to let that call complete
        sleep(2)

        let requested1 = try XCTUnwrap(requestedFeatures[0] as? MockFeature)
        XCTAssertNotEqual(feature1, requested1, "features should not be equal because impression ids should be updated")

        XCTAssertEqual(requested1.impressionIds, [fakeImpressionId])
        XCTAssertEqual(feature1.impressionIds, [initialImpressionId])

        XCTAssertEqual(try requested1.args(), try feature1.args(), "args should be equal")
        XCTAssertNotEqual(requested1.impressionIds, feature1.impressionIds, "impression ids should be updated")

        let requested2 = try XCTUnwrap(requestedFeatures[1] as? RatingBox)
        XCTAssertNotEqual(feature2, requested2, "features should not be equal because impression ids should be updated")

        XCTAssertEqual(requested2.impressionIds, [fakeImpressionId])
        XCTAssertEqual(feature2.impressionIds, [initialImpressionId])

        XCTAssertEqual(try requested2.args(), try feature2.args(), "args should be equal")
        XCTAssertNotEqual(requested2.impressionIds, feature2.impressionIds, "impression ids should be updated")

        // Verify NetworkClient was only called twice
        // And the most recent call should have been to signal
        XCTAssertEqual(mockNetworkingClient.sendRequestCallCount, 2, "should get features from cache, and signal")
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .signal, "should hit signal endpoint for cached features")
    }

    func test_requestCacheFill() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let cache = await FeatureCache()
        let client = CausalClient.fake(featureCache: cache, mockNetworkingClient: mockNetworkingClient)

        let features: [any FeatureProtocol] = [
            MockFeature(),
            RatingBox(productName: "name", productPrice: 10)
        ]

        var isEmpty = await cache.isEmpty
        XCTAssertTrue(isEmpty)

        try await client.requestCacheFill(features: features)

        // Verify NetworkClient was called
        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled)

        // Verify cache saved features
        isEmpty = await cache.isEmpty
        XCTAssertFalse(isEmpty)

        let count = await cache.count
        XCTAssertEqual(count, 2)
    }

    func test_requestCacheFill_onlyRequestsNonCachedFeatures() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let cache = await FeatureCache()
        let client = CausalClient.fake(featureCache: cache, mockNetworkingClient: mockNetworkingClient)
        let session = MockSession()

        let savedFeatures: [any FeatureProtocol] = [
            MockFeature(),
            RatingBox(productName: "one", productPrice: 10)
        ]

        // Save 2 features in the cache
        await cache.save(all: savedFeatures)
        let contains0 = await cache.contains(savedFeatures[0])
        let contains1 = await cache.contains(savedFeatures[1])
        XCTAssertTrue(contains0 && contains1)

        // 2 new features to request
        let newFeatures: [any FeatureProtocol] = [
            RatingBox(productName: "two", productPrice: 20),
            RatingBox(productName: "three", productPrice: 30)
        ]

        // Request all the features to be cached
        let allFeatures = savedFeatures + newFeatures
        try await client.requestCacheFill(features: allFeatures)

        // Check the network request
        let receivedBody = try XCTUnwrap(mockNetworkingClient.receivedBody)
        let (_, requestedFeatures) = try JSONProcessor().decodeRequestFeatures(
            response: receivedBody,
            features: newFeatures,
            session: session
        )

        // Verify we only requested the 2 new features
        let requestedFeatureIds = requestedFeatures.map { $0.id }
        let newFeaturesIds = newFeatures.map { $0.id }
        XCTAssertEqual(requestedFeatureIds, newFeaturesIds)
    }

    func test_requestFeature_assignNewSession_requestFeatureAgain() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let cache = await FeatureCache()
        let initialSession = MockSession()
        let timer = SessionTimer()
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient,
            sessionTimer: timer,
            session: initialSession
        )

        let feature = RatingBox(productName: "name", productPrice: 10)
        var isEmpty = await cache.isEmpty
        XCTAssertTrue(isEmpty)

        _ = try await client.requestFeature(
            feature: feature,
            impressionId: fakeImpressionId
        )

        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled, "network client should be called")
        XCTAssertFalse(timer.isExpired, "session should be valid")

        // Verify cache saved features
        isEmpty = await cache.isEmpty
        XCTAssertFalse(isEmpty)

        let count = await cache.count
        XCTAssertEqual(count, 1)

        // Assign new session
        let newSession = Session(deviceId: fakeDeviceId, required: 99)
        client.session = newSession

        // Request the same feature
        _ = try await client.requestFeature(
            feature: feature,
            impressionId: fakeImpressionId
        )

        // Network client should be called again, because cache was invalid
        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled, "network client should be called")
    }

    func test_defaultValues() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let cache = await FeatureCache()
        let initialSession = MockSession()
        let timer = SessionTimer()
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient,
            sessionTimer: timer,
            session: initialSession
        )

        let price = Price(currency: Currency.USD, amount: 10.0)

        var crossSell1 = CrossSell(productId: "1234", price: price )

        crossSell1 = try await client.requestFeature(feature: crossSell1)

        let body1 = try XCTUnwrap(mockNetworkingClient.receivedBodyString)
        XCTAssertTrue(body1.contains("another default"))

        try await crossSell1.signalAndWaitEventA(client: client)
        XCTAssertTrue(mockNetworkingClient.receivedBodyString.contains("7777"))

        try await crossSell1.signalAndWaitEventA(client: client, anInt: 8_888)
        XCTAssertTrue(mockNetworkingClient.receivedBodyString.contains("8888"))

        var crossSell2 = CrossSell(productId: "1234", price: price, withDefault: "different value")
        crossSell2 = try await client.requestFeature(feature: crossSell2)

        let body2 = try XCTUnwrap(mockNetworkingClient.receivedBodyString)
        XCTAssertTrue(body2.contains("different value"))
        XCTAssertFalse(body2.contains("another default"))
    }
}
