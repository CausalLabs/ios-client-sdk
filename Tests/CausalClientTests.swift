//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//
// swiftlint:disable file_length

@testable import CausalLabsSDK
import XCTest

// swiftlint:disable:next type_body_length
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
        CausalClient.shared.impressionServer = fakeImpressionServer
        CausalClient.shared.session = MockSession()
        XCTAssertNotNil(CausalClient.shared.session)
    }

    func test_requestFeatures_hitsCorrectEndpoint() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let client = await CausalClient.fake(featureCache: .shared, mockNetworkingClient: mockNetworkingClient)

        _ = await client.requestFeatures(
            [MockFeature()],
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

        let result = await client.requestFeatures(
            [RatingBox(productName: "name", productPrice: 10)],
            impressionId: fakeImpressionId
        )
        XCTAssertTrue(result is CausalError)
        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled, "network client should be called")
    }

    func test_requestFeatures_throwsError_missingSession() async throws {
        let client = await CausalClient.fake(featureCache: .shared)
        client.session = nil

        let result = await client.requestFeatures([MockFeature()])
        XCTAssertEqual(result as? CausalError, CausalError.missingSession)
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

        await AsyncAssertThrowsError(
            try await client.signalAndWait(event: MockEvent(), impressionId: fakeImpressionId),
            "client should throw error from networking client"
        )

        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled, "network client should be called")
    }

    func test_signalEvent_throwsError_missingSession() async throws {
        let client = await CausalClient.fake(featureCache: .shared)
        client.session = nil

        await AsyncAssertThrowsError(
            try await client.signalAndWait(event: MockEvent(), impressionId: fakeImpressionId)
        ) { error in
            XCTAssertEqual(error as? CausalError, CausalError.missingSession)
        }
    }

    func test_keepAlive_hitsCorrectEndpoint() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let session = Session(deviceId: "id", required: 42)
        let client = await CausalClient.fake(
            featureCache: .shared,
            mockNetworkingClient: mockNetworkingClient,
            session: session
        )

        client.keepAlive()
        // fire-and-forget, so sleep to let call complete
        sleep(2)

        XCTAssertEqual(mockNetworkingClient.receivedBaseURL, fakeImpressionServer)
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .signal)

        XCTAssertEqual(mockNetworkingClient.receivedSession as? Session, session)
        XCTAssertEqual(mockNetworkingClient.receivedBody, try session.keys().data())
    }

    func test_clearCache() async throws {
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
                    "_impressionId": "response-impression-id",
                },
                {
                    "product": "name",
                    "productPrice": 42,
                    "_impressionId": "response-impression-id",
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

    func test_requestFeatures_updatesInPlace_andCachesUpdates() async throws {
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
                    "_impressionId": "response-impression-id",
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
        XCTAssertNil(feature.impressionId)

        let isEmpty = await cache.isEmpty
        XCTAssertTrue(isEmpty)

        let requestImpressionId = "request impression id"
        let error = await client.requestFeatures([feature], impressionId: requestImpressionId)
        XCTAssertNil(error)

        // Arguments
        XCTAssertEqual(feature.productName, "name")
        XCTAssertEqual(feature.productPrice, 42)

        // Outputs
        XCTAssertEqual(feature.callToAction, "Different Call To Action")
        XCTAssertEqual(feature.actionButton, "Different Action Button")
        XCTAssertEqual(feature.impressionId, requestImpressionId)

        // Verify cache saved feature
        let count = await cache.count
        XCTAssertEqual(count, 1)

        let contains = await cache.contains(feature)
        XCTAssertTrue(contains)
    }

    func test_requestFeatures_withEmptyCache_savesToCache() async throws {
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
                    "_impressionId": "response-impression-id",
                },
                {
                    "product": "name",
                    "productPrice": 42,
                    "_impressionId": "response-impression-id",
                    "callToAction": "Different Call To Action",
                    "actionButton": "Different Action Button"
                }
            ]
        }
        """

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

        await client.requestFeatures(
            features,
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

    @MainActor
    func test_requestFeatures_WITH_emptyCache_SHOULD_mutateFeaturesWithResponseValues() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let cache = FeatureCache()
        let timer = SessionTimer()
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient,
            sessionTimer: timer
        )

        let feature1 = ProductDisplay(productName: "displayName", price: .init(currency: .EUR, amount: 25.99))
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]

        XCTAssertEqual(cache.count, 0)

        mockNetworkingClient.stubbedResponse = """
        {
            "session": {
                "deviceId": "8EB5B974-6BDF-44ED-8D1B-C1215C3B0FA3",
                "sessionId": "f45f7661-c338-4d24-9f00-1b02c3cf68f7",
                "startTime": 1687298716527
            },
            "impressions": [
                {
                    "productName": "name",
                    "price": {
                        "currency": "EUR",
                        "amount": 25.99
                    },
                    "_impressionId": "response _impressionId",
                },
                {
                    "productName": "name",
                    "productPrice": 10,
                    "_impressionId": "response _impressionId",
                    "callToAction": "response callToAction",
                    "actionButton": "response actionButton"
                },
            ]
        }
        """

        let requestImpressionId = "request impression id"
        await client.requestFeatures(features, impressionId: requestImpressionId)

        XCTAssertEqual(feature1.productName, "displayName")
        XCTAssertEqual(feature1.price, .init(currency: .EUR, amount: 25.99))
        XCTAssertTrue(feature1.isActive)
        XCTAssertEqual(feature1.impressionId, requestImpressionId)

        XCTAssertEqual(feature2.productName, "name")
        XCTAssertEqual(feature2.productPrice, 10)
        XCTAssertEqual(feature2.actionButton, "response actionButton")
        XCTAssertEqual(feature2.callToAction, "response callToAction")
        XCTAssertEqual(feature2.impressionId, requestImpressionId)
    }

    @MainActor
    func test_requestFeatures_WITH_fullCache_SHOULD_mutateFeaturesWithCachedValues() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let cache = FeatureCache()
        let timer = SessionTimer()
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient,
            sessionTimer: timer
        )

        let feature1 = ProductDisplay(productName: "displayName", price: .init(currency: .EUR, amount: 25.99))
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]

        let cachedFeature1 = ProductDisplay(productName: "displayName", price: .init(currency: .EUR, amount: 25.99))
        try cachedFeature1.update(
            outputJson: [
                "_impressionId": "cached _impressionId"
            ],
            isActive: true
        )

        let cachedFeature2 = RatingBox(productName: "name", productPrice: 10)
        try cachedFeature2.update(
            outputJson: [
                "actionButton": "cached actionButton",
                "callToAction": "cached callToAction",
                "_impressionId": "cached _impressionId"
            ],
            isActive: false
        )

        try cache.save(cachedFeature1)
        try cache.save(cachedFeature2)

        let requestImpressionId = "request impression id"
        await client.requestFeatures(features, impressionId: requestImpressionId)
        XCTAssertEqual(feature1.productName, "displayName")
        XCTAssertEqual(feature1.price, .init(currency: .EUR, amount: 25.99))
        XCTAssertTrue(feature1.isActive)
        XCTAssertEqual(feature1.impressionId, requestImpressionId)

        XCTAssertEqual(feature2.productName, "name")
        XCTAssertEqual(feature2.productPrice, 10)
        XCTAssertEqual(feature2.actionButton, "cached actionButton")
        XCTAssertEqual(feature2.callToAction, "cached callToAction")
        XCTAssertEqual(feature2.impressionId, requestImpressionId)
    }

    @MainActor
    func test_requestFeature_WITH_emptyCache_SHOULD_mutateFeaturesWithResponseValues() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let cache = FeatureCache()
        let timer = SessionTimer()
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient,
            sessionTimer: timer
        )

        let feature = RatingBox(productName: "name", productPrice: 10)

        XCTAssertEqual(cache.count, 0)

        mockNetworkingClient.stubbedResponse = """
        {
            "session": {
                "deviceId": "8EB5B974-6BDF-44ED-8D1B-C1215C3B0FA3",
                "sessionId": "f45f7661-c338-4d24-9f00-1b02c3cf68f7",
                "startTime": 1687298716527
            },
            "impressions": [
                {
                    "productName": "name",
                    "productPrice": 10,
                    "callToAction": "response callToAction",
                    "actionButton": "response actionButton"
                },
            ]
        }
        """

        let requestImpressionId = "request impression id"
        await client.requestFeature(feature, impressionId: requestImpressionId)

        XCTAssertEqual(feature.productName, "name")
        XCTAssertEqual(feature.productPrice, 10)
        XCTAssertEqual(feature.actionButton, "response actionButton")
        XCTAssertEqual(feature.callToAction, "response callToAction")
        XCTAssertEqual(feature.impressionId, requestImpressionId)
    }

    @MainActor
    func test_requestFeature_WITH_fullCache_SHOULD_mutateFeaturesWithCachedValues() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let cache = FeatureCache()
        let timer = SessionTimer()
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient,
            sessionTimer: timer
        )

        let feature = RatingBox(productName: "name", productPrice: 10)

        let cachedFeature = RatingBox(productName: "name", productPrice: 10)
        try cachedFeature.update(
            outputJson: [
                "actionButton": "cached actionButton",
                "callToAction": "cached callToAction",
                "_impressionId": "cached _impressionId"
            ],
            isActive: false
        )

        try cache.save(cachedFeature)

        let requestImpressionId = "request impression id"
        await client.requestFeature(feature, impressionId: requestImpressionId)

        XCTAssertEqual(feature.productName, "name")
        XCTAssertEqual(feature.productPrice, 10)
        XCTAssertEqual(feature.actionButton, "cached actionButton")
        XCTAssertEqual(feature.callToAction, "cached callToAction")
        XCTAssertEqual(feature.impressionId, requestImpressionId)
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

        let feature1 = RatingBox(productName: "feature1", productPrice: 1)
        feature1.impressionId = initialImpressionId

        let feature2 = RatingBox(productName: "feature2", productPrice: 2)
        feature2.impressionId = initialImpressionId

        let features: [any FeatureProtocol] = [feature1, feature2]

        mockNetworkingClient.stubbedResponse = """
        {
            "session": {
                "deviceId": "8EB5B974-6BDF-44ED-8D1B-C1215C3B0FA3",
                "sessionId": "f45f7661-c338-4d24-9f00-1b02c3cf68f7",
                "startTime": 1687298716527
            },
            "impressions": [
                {
                    "productName": "feature1",
                    "productPrice": 1,
                    "callToAction": "feature1 cached callToAction",
                    "actionButton": "feature1 cached actionButton"
                },
                {
                    "productName": "feature2",
                    "productPrice": 2,
                    "callToAction": "feature2 cached callToAction",
                    "actionButton": "feature2 cached actionButton"
                },
            ]
        }
        """

        // request cache fill
        try await client.requestCacheFill(features: features)
        XCTAssertEqual(mockNetworkingClient.sendRequestCallCount, 1, "should hit network to fill cache")
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .features, "should hit features endpoint")

        let isEmpty = await cache.isEmpty
        XCTAssertFalse(isEmpty)

        let count = await cache.count
        XCTAssertEqual(count, 2)

        // request same features
        await client.requestFeatures(features, impressionId: fakeImpressionId)

        // we asynchronously signal cached features
        // thus, sleep to let that call complete
        sleep(2)

        // Impression id should be updated.
        XCTAssertEqual(feature1.impressionId, fakeImpressionId)
        XCTAssertEqual(feature1.callToAction, "feature1 cached callToAction")
        XCTAssertEqual(feature1.actionButton, "feature1 cached actionButton")

        XCTAssertEqual(feature2.impressionId, fakeImpressionId)
        XCTAssertEqual(feature2.callToAction, "feature2 cached callToAction")
        XCTAssertEqual(feature2.actionButton, "feature2 cached actionButton")

        // Verify NetworkClient was only called twice
        // And the most recent call should have been to signal
        XCTAssertEqual(mockNetworkingClient.sendRequestCallCount, 2, "should get features from cache, and signal")
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .signal, "should hit signal endpoint for cached features")
    }

    func test_requestCacheFill() async throws {
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
                    "_impressionId": "response-impression-id",
                },
                {
                    "product": "name",
                    "productPrice": 42,
                    "_impressionId": "response-impression-id",
                    "callToAction": "Different Call To Action",
                    "actionButton": "Different Action Button"
                }
            ]
        }
        """
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

    func test_requestFeature_assignNewSession_requestFeatureAgain() async throws {
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
                    "_impressionId": "response-impression-id",
                    "callToAction": "Different Call To Action",
                    "actionButton": "Different Action Button"
                }
            ]
        }
        """

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

        await client.requestFeature(feature, impressionId: fakeImpressionId)

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
        await client.requestFeature(feature, impressionId: fakeImpressionId)

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

        let crossSell1 = CrossSell(productId: "1234", price: price )

        await client.requestFeature(crossSell1)

        let body1 = try XCTUnwrap(mockNetworkingClient.receivedBodyString)
        XCTAssertTrue(body1.contains("another default"))

        try await crossSell1.signalAndWaitEventA(client: client)
        XCTAssertTrue(mockNetworkingClient.receivedBodyString.contains("7777"))

        try await crossSell1.signalAndWaitEventA(client: client, anInt: 8_888)
        XCTAssertTrue(mockNetworkingClient.receivedBodyString.contains("8888"))

        let crossSell2 = CrossSell(productId: "1234", price: price, withDefault: "different value")
        await client.requestFeature(crossSell2)

        let body2 = try XCTUnwrap(mockNetworkingClient.receivedBodyString)
        XCTAssertTrue(body2.contains("different value"))
        XCTAssertFalse(body2.contains("another default"))
    }
}
