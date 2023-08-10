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
        let client = CausalClient.fake(mockNetworkingClient: mockNetworkingClient)

        _ = await client.requestFeatures(
            [ProductInfo()],
            impressionId: fakeImpressionId
        )

        XCTAssertEqual(mockNetworkingClient.receivedBaseURL, fakeImpressionServer)
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .features)
    }

    func test_requestFeatures_throwsErrorFromNetwork() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        mockNetworkingClient.stubbedError = CausalError.fakeNetwork()

        let client = CausalClient.fake(mockNetworkingClient: mockNetworkingClient)

        let result = await client.requestFeatures(
            [RatingBox(productName: "name", productPrice: 10)],
            impressionId: fakeImpressionId
        )
        XCTAssertTrue(result is CausalError)
        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled, "network client should be called")
    }

    func test_requestFeatures_throwsError_missingSession() async throws {
        let client = CausalClient.fake()
        client.session = nil

        let result = await client.requestFeatures([ProductInfo()])
        XCTAssertEqual(result as? CausalError, CausalError.missingSession)
    }

    func test_signalAndWait_feature_hitsCorrectEndpoint() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let client = CausalClient.fake(mockNetworkingClient: mockNetworkingClient)

        let mockEvent = MockFeatureEvent()
        try await client.signalAndWait(
            featureEvent: (event: mockEvent, impressionId: fakeImpressionId)
        )

        XCTAssertEqual(mockNetworkingClient.receivedBaseURL, fakeImpressionServer)
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .signal)
        XCTAssertEqual(mockNetworkingClient.receivedBodyJSON["impressionId"], fakeImpressionId)
        XCTAssertEqual(mockNetworkingClient.receivedBodyJSON["event"] as? String, mockEvent.name)
        XCTAssertEqual(mockNetworkingClient.receivedBodyJSON["args"] as? JSONObject, mockEvent.serialized())
        XCTAssertEqual(mockNetworkingClient.receivedBodyJSON["id"] as? JSONObject, ["deviceId": "MockDeviceId"])
    }

    func test_signalAndWait_session_hitsCorrectEndpoint() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let client = CausalClient.fake(mockNetworkingClient: mockNetworkingClient)

        let mockEvent = MockSessionEvent()
        try await client.signalAndWait(sessionEvent: mockEvent)

        XCTAssertEqual(mockNetworkingClient.receivedBaseURL, fakeImpressionServer)
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .signal)
        XCTAssertNil(mockNetworkingClient.receivedBodyJSON["impressionId"])
        XCTAssertEqual(mockNetworkingClient.receivedBodyJSON["event"] as? String, mockEvent.name)
        XCTAssertEqual(mockNetworkingClient.receivedBodyJSON["args"] as? JSONObject, mockEvent.serialized())
        XCTAssertEqual(mockNetworkingClient.receivedBodyJSON["id"] as? JSONObject, ["deviceId": "MockDeviceId"])
    }

    func test_signalAndWait_feature_throwsErrorFromNetwork() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        mockNetworkingClient.stubbedError = CausalError.fakeNetwork()

        let client = CausalClient.fake(mockNetworkingClient: mockNetworkingClient)

        await AsyncAssertThrowsError(
            try await client.signalAndWait(featureEvent: (event: MockFeatureEvent(), impressionId: fakeImpressionId)),
            "client should throw error from networking client"
        )

        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled, "network client should be called")
    }

    func test_signalAndWait_session_throwsErrorFromNetwork() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        mockNetworkingClient.stubbedError = CausalError.fakeNetwork()

        let client = CausalClient.fake(mockNetworkingClient: mockNetworkingClient)

        await AsyncAssertThrowsError(
            try await client.signalAndWait(sessionEvent: MockSessionEvent()),
            "client should throw error from networking client"
        )

        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled, "network client should be called")
    }

    func test_signalAndWait_feature_throwsError_missingSession() async throws {
        let client = CausalClient.fake()
        client.session = nil

        await AsyncAssertThrowsError(
            try await client.signalAndWait(featureEvent: (event: MockFeatureEvent(), impressionId: fakeImpressionId))
        ) { error in
            XCTAssertEqual(error as? CausalError, CausalError.missingSession)
        }
    }

    func test_signalAndWait_session_throwsError_missingSession() async throws {
        let client = CausalClient.fake()
        client.session = nil

        await AsyncAssertThrowsError(
            try await client.signalAndWait(sessionEvent: MockSessionEvent())
        ) { error in
            XCTAssertEqual(error as? CausalError, CausalError.missingSession)
        }
    }

    func test_keepAlive_hitsCorrectEndpoint() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let session = Session(deviceId: "id", required: 42)
        let client = CausalClient.fake(
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

        let cache = FeatureCache()
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient
        )

        let features: [any FeatureProtocol] = [
            ProductInfo(),
            RatingBox(productName: "name", productPrice: 10)
        ]

        // request cache fill
        try await client.requestCacheFill(features: features)
        XCTAssertEqual(cache.count, 2)

        client.clearCache()
        XCTAssertTrue(cache.isEmpty)
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

        let cache = FeatureCache()
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient
        )

        let feature = RatingBox(productName: "name", productPrice: 42)
        XCTAssertEqual(feature.status, .unrequested)
        XCTAssertTrue(cache.isEmpty)

        let requestImpressionId = "request impression id"
        let error = await client.requestFeatures([feature], impressionId: requestImpressionId)
        XCTAssertNil(error)

        // Arguments
        XCTAssertEqual(feature.args.productName, "name")
        XCTAssertEqual(feature.args.productPrice, 42)

        // Outputs
        guard case let .on(outputs) = feature.status else {
            XCTFail("Expected `on` status.")
            return
        }

        XCTAssertEqual(outputs.callToAction, "Different Call To Action")
        XCTAssertEqual(outputs.actionButton, "Different Action Button")
        XCTAssertEqual(outputs._impressionId, requestImpressionId)

        // Verify cache saved feature
        XCTAssertEqual(cache.count, 1)

        XCTAssertTrue(cache.contains(feature))
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

        let cache = FeatureCache()
        let timer = SessionTimer()
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient,
            sessionTimer: timer
        )

        let features: [any FeatureProtocol] = [
            ProductInfo(),
            RatingBox(productName: "name", productPrice: 10)
        ]

        XCTAssertTrue(cache.isEmpty)
        XCTAssertTrue(timer.isExpired)

        await client.requestFeatures(
            features,
            impressionId: fakeImpressionId
        )

        // Verify NetworkClient was called
        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled)

        // Verify cache saved features
        XCTAssertFalse(cache.isEmpty)

        XCTAssertEqual(cache.count, 2)

        // Verify session is valid
        XCTAssertFalse(timer.isExpired)
    }

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

        XCTAssertEqual(feature1.args.productName, "displayName")
        XCTAssertEqual(feature1.args.price, .init(currency: .EUR, amount: 25.99))

        guard case let .on(outputs1) = feature1.status else {
            XCTFail("Expected `on` status.")
            return
        }

        XCTAssertEqual(outputs1._impressionId, requestImpressionId)

        XCTAssertEqual(feature2.args.productName, "name")
        XCTAssertEqual(feature2.args.productPrice, 10)

        guard case let .on(outputs2) = feature2.status else {
            XCTFail("Expected `on` status.")
            return
        }

        XCTAssertEqual(outputs2.actionButton, "response actionButton")
        XCTAssertEqual(outputs2.callToAction, "response callToAction")
        XCTAssertEqual(outputs2._impressionId, requestImpressionId)
    }

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
            request: .on(
                outputJson: [
                    "_impressionId": "cached _impressionId"
                ],
                impressionId: nil
            )
        )

        let cachedFeature2 = RatingBox(productName: "name", productPrice: 10)
        try cachedFeature2.update(request: .off)

        try cache.save(cachedFeature1)
        try cache.save(cachedFeature2)

        let requestImpressionId = "request impression id"
        await client.requestFeatures(features, impressionId: requestImpressionId)
        XCTAssertEqual(feature1.args.productName, "displayName")
        XCTAssertEqual(feature1.args.price, .init(currency: .EUR, amount: 25.99))

        guard case let .on(outputs1) = feature1.status else {
            XCTFail("Expected `on` status.")
            return
        }

        XCTAssertEqual(outputs1._impressionId, requestImpressionId)

        XCTAssertEqual(feature2.args.productName, "name")
        XCTAssertEqual(feature2.args.productPrice, 10)
        XCTAssertEqual(feature2.status, .off)
    }

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

        XCTAssertEqual(feature.args.productName, "name")
        XCTAssertEqual(feature.args.productPrice, 10)

        guard case let .on(outputs) = feature.status else {
            XCTFail("Expected `on` status.")
            return
        }

        XCTAssertEqual(outputs.actionButton, "response actionButton")
        XCTAssertEqual(outputs.callToAction, "response callToAction")
        XCTAssertEqual(outputs._impressionId, requestImpressionId)
    }

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
            request: .on(
                outputJson: [
                    "actionButton": "cached actionButton",
                    "callToAction": "cached callToAction",
                    "_impressionId": "cached _impressionId"
                ],
                impressionId: nil
            )
        )

        try cache.save(cachedFeature)

        let requestImpressionId = "request impression id"
        await client.requestFeature(feature, impressionId: requestImpressionId)

        XCTAssertEqual(feature.args.productName, "name")
        XCTAssertEqual(feature.args.productPrice, 10)

        guard case let .on(outputs) = feature.status else {
            XCTFail("Expected `on` status.")
            return
        }

        XCTAssertEqual(outputs.actionButton, "cached actionButton")
        XCTAssertEqual(outputs.callToAction, "cached callToAction")
        XCTAssertEqual(outputs._impressionId, requestImpressionId)
    }

    func test_requestFeatures_withFullCache_fetchesFromCache() async throws {
        let mockNetworkingClient = MockNetworkingClient()
        let cache = FeatureCache()
        let timer = SessionTimer()
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient,
            sessionTimer: timer
        )

        let feature1 = MockFeatureA(arg1: "feature1")
        let feature2 = MockFeatureB(arg1: "feature2")
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
                    "arg1": "feature1",
                    "out1": "feature1 cached out1",
                    "out2": 2,
                    "_impressionId": "server-impression-id"
                },
                {
                    "arg1": "feature2",
                    "out1": "feature2 cached out1",
                    "out2": 3,
                    "_impressionId": "server-impression-id"
                },
            ]
        }
        """

        // request cache fill
        try await client.requestCacheFill(features: features)
        XCTAssertEqual(mockNetworkingClient.sendRequestCallCount, 1, "should hit network to fill cache")
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .features, "should hit features endpoint")

        let isEmpty = cache.isEmpty
        XCTAssertFalse(isEmpty)

        let count = cache.count
        XCTAssertEqual(count, 2)

        // request same features
        let requestResponse = await client.requestFeatures(features, impressionId: fakeImpressionId)
        XCTAssertNil(requestResponse)

        // we asynchronously signal cached features
        // thus, sleep to let that call complete
        sleep(2)

        guard case let .on(outputs1) = feature1.status,
              case let .on(outputs2) = feature2.status else {
            XCTFail("Expected `on` status.")
            return
        }

        // Impression id should be updated.
        XCTAssertEqual(outputs1._impressionId, fakeImpressionId)
        XCTAssertEqual(outputs1.out1, "feature1 cached out1")
        XCTAssertEqual(outputs1.out2, 2)

        XCTAssertEqual(outputs2._impressionId, fakeImpressionId)
        XCTAssertEqual(outputs2.out1, "feature2 cached out1")
        XCTAssertEqual(outputs2.out2, 3)

        // Verify NetworkClient was only called twice
        // And the most recent call should have been to signal
        XCTAssertEqual(mockNetworkingClient.sendRequestCallCount, 2, "should get features from cache, and signal")
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .signal, "should hit signal endpoint for cached features")
    }

    func test_requestCacheFill_SHOULD_makeAPICall() async throws {
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
        let client = CausalClient.fake(mockNetworkingClient: mockNetworkingClient)

        let features: [any FeatureProtocol] = [
            ProductInfo(),
            RatingBox(productName: "name", productPrice: 10)
        ]

        try await client.requestCacheFill(features: features)

        // Verify NetworkClient was called
        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled)
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .features)
        // swiftlint:disable:next line_length
        XCTAssertEqual(mockNetworkingClient.receivedBodyString, "{\n  \"args\" : {\n    \"deviceId\" : \"MockDeviceId\"\n  },\n  \"reqs\" : [\n    {\n      \"name\" : \"ProductInfo\",\n      \"args\" : {\n\n      }\n    },\n    {\n      \"name\" : \"RatingBox\",\n      \"args\" : {\n        \"productName\" : \"name\",\n        \"productPrice\" : 10\n      }\n    }\n  ]\n}")
    }

    func test_requestCacheFill_SHOULD_addValuesToTheCache() async throws {
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
        let cache = FeatureCache()
        let client = CausalClient.fake(featureCache: cache, mockNetworkingClient: mockNetworkingClient)

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]

        XCTAssertTrue(cache.isEmpty)

        try await client.requestCacheFill(features: features)

        // Verify cache saved features
        XCTAssertFalse(cache.isEmpty)
        XCTAssertEqual(cache.count, 2)
        XCTAssertEqual(
            cache.fetch(feature1),
            .init(
                name: "ProductInfo",
                status: .on(
                    outputsJson: ["_impressionId": "response-impression-id"],
                    cachedImpressionId: "response-impression-id"
                )
            )
        )
        XCTAssertEqual(
            cache.fetch(feature2),
            .init(
                name: "RatingBox",
                status: .on(
                    outputsJson: [
                        "callToAction": "Different Call To Action",
                        "_impressionId": "response-impression-id",
                        "actionButton": "Different Action Button"
                    ],
                    cachedImpressionId: "response-impression-id"
                )
            )
        )
    }

    func test_requestCacheFill_SHOULD_notUpdateInputFeatureStatus() async throws {
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
        let cache = FeatureCache()
        let client = CausalClient.fake(featureCache: cache, mockNetworkingClient: mockNetworkingClient)

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]

        try await client.requestCacheFill(features: features)

        XCTAssertEqual(feature1.status, .unrequested)
        XCTAssertEqual(feature2.status, .unrequested)
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

        let cache = FeatureCache()
        let initialSession = MockSession()
        let timer = SessionTimer()
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient,
            sessionTimer: timer,
            session: initialSession
        )

        let feature = RatingBox(productName: "name", productPrice: 10)
        XCTAssertTrue(cache.isEmpty)

        await client.requestFeature(feature, impressionId: fakeImpressionId)

        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled, "network client should be called")
        XCTAssertFalse(timer.isExpired, "session should be valid")

        // Verify cache saved features
        XCTAssertFalse(cache.isEmpty)

        XCTAssertEqual(cache.count, 1)

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
        mockNetworkingClient.stubbedResponse = """
        {
            "session": {
                "deviceId": "8EB5B974-6BDF-44ED-8D1B-C1215C3B0FA3",
                "sessionId": "f45f7661-c338-4d24-9f00-1b02c3cf68f7",
                "startTime": 1687298716527
            },
            "impressions": [
                {
                    "productId": "server product id",
                    "baseOnly": "base",
                    "customerData": {
                        "zip": "02445",
                        "productViews": 1,
                        "lastViews": ["123", "456"]
                    },
                    "crosssellProductids": ["60745"],
                    "nullable": "server nullable response",
                    "_impressionId": "server impression id"
                }
            ]
        }
        """

        let cache = FeatureCache()
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

        let result = await client.requestFeature(crossSell1)
        XCTAssertNil(result)

        let body1 = try XCTUnwrap(mockNetworkingClient.receivedBodyString)
        XCTAssertTrue(body1.contains("another default"))

        try await client.signalAndWait(featureEvent: crossSell1.event(.eventA()))
        XCTAssertTrue(mockNetworkingClient.receivedBodyString.contains("7777"))

        try await client.signalAndWait(featureEvent: crossSell1.event(.eventA(anInt: 8_888)))
        XCTAssertTrue(mockNetworkingClient.receivedBodyString.contains("8888"))

        let crossSell2 = CrossSell(productId: "1234", price: price, withDefault: "different value")
        await client.requestFeature(crossSell2)

        let body2 = try XCTUnwrap(mockNetworkingClient.receivedBodyString)
        XCTAssertTrue(body2.contains("different value"))
        XCTAssertFalse(body2.contains("another default"))
    }
}
