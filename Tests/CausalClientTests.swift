//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//
// swiftlint:disable file_length

@testable import CausalLabsSDK
import XCTest

// swiftlint:disable:next type_body_length
final class CausalClientTests: XCTestCase {
    private var mockNetworkingClient: MockNetworkingClient!
    private var mockObserverStore: MockObserverStore!
    private var mockFeatureCache: MockFeatureCache!
    private var mockLogger: Logger!
    private var mockSessionTimer: MockSessionTimer!
    private var mockSSEClientFactory: MockSSEClientFactory!
    private var mockJSONProcessor: JSONProcessor!
    private var sut: CausalClient!

    override func setUp() {
        super.setUp()

        mockNetworkingClient = MockNetworkingClient()
        mockObserverStore = MockObserverStore()
        mockFeatureCache = MockFeatureCache()
        mockLogger = Logger()
        mockSessionTimer = MockSessionTimer()
        mockSSEClientFactory = MockSSEClientFactory()
        mockJSONProcessor = JSONProcessor(logger: mockLogger)

        sut = CausalClient(
            networkClient: mockNetworkingClient,
            jsonProcessor: mockJSONProcessor,
            featureCache: mockFeatureCache,
            sessionTimer: mockSessionTimer,
            sseClientFactory: mockSSEClientFactory,
            observerStore: mockObserverStore,
            logger: .shared
        )

        sut.session = MockSession()
        sut.impressionServer = fakeImpressionServer
    }

    func test_impressionServer() {
        sut.impressionServer = fakeImpressionServer
        XCTAssertNotNil(sut.impressionServer)

        let url = URL(string: "https://causallabs.io")!
        sut.impressionServer = url
        XCTAssertEqual(
            sut.impressionServer,
            url,
            "You should be able to reset the impression server URL"
        )
    }

    func test_session() {
        sut.impressionServer = fakeImpressionServer
        sut.session = MockSession()
        XCTAssertNotNil(sut.session)
    }

    // MARK: requestFeatures

    func test_requestFeatures_hitsCorrectEndpoint() async throws {
        _ = await sut.requestFeatures(
            [ProductInfo()],
            impressionId: fakeImpressionId
        )

        XCTAssertEqual(mockNetworkingClient.receivedBaseURL, fakeImpressionServer)
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .features)
    }

    func test_requestFeatures_throwsErrorFromNetwork() async throws {
        mockNetworkingClient.stubbedError = CausalError.fakeNetwork()

        let result = await sut.requestFeatures(
            [RatingBox(productName: "name", productPrice: 10)],
            impressionId: fakeImpressionId
        )
        XCTAssertTrue(result is CausalError)
        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled, "network client should be called")
    }

    func test_requestFeatures_throwsError_missingSession() async throws {
        sut.session = nil
        let result = await sut.requestFeatures([ProductInfo()])
        XCTAssertEqual(result as? CausalError, CausalError.missingSession)
    }

    func test_requestFeatures_SHOULD_updateFeaturesWithDefaultStatus_WHEN_throwsErrorFromNetwork() async throws {
        mockNetworkingClient.stubbedError = CausalError.fakeNetwork()

        let feature1 = RatingBox(productName: "name1", productPrice: 1)
        let feature2 = RatingBox(productName: "name2", productPrice: 2)
        let feature3 = CrossSellDefaultOff(productId: "id1")

        XCTAssertEqual(feature1.status, .unrequested)
        XCTAssertEqual(feature2.status, .unrequested)
        XCTAssertEqual(feature3.status, .unrequested)

        await sut.requestFeatures([feature1, feature2, feature3], impressionId: fakeImpressionId)

        XCTAssertEqual(feature1.status, .on(outputs: .defaultValues))
        XCTAssertEqual(feature2.status, .on(outputs: .defaultValues))
        XCTAssertEqual(feature3.status, .off)
    }

    func test_requestFeatures_updatesInPlace_andCachesUpdates() async throws {
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

        let feature = RatingBox(productName: "name", productPrice: 42)
        XCTAssertEqual(feature.status, .unrequested)

        let requestImpressionId = "request impression id"
        let error = await sut.requestFeatures([feature], impressionId: requestImpressionId)
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

        XCTAssertEqual(mockFeatureCache.calls.saveItems, [
            [
                FeatureCacheItem(
                    key: FeatureKey(
                        name: "RatingBox",
                        argsJson: [
                            "productName": "name",
                            "productPrice": 42
                        ]
                    ),
                    status: .on(outputsJson: [
                        "product": "name",
                        "productPrice": 42,
                        "_impressionId": "response-impression-id",
                        "callToAction": "Different Call To Action",
                        "actionButton": "Different Action Button"
                    ])
                )
            ]
        ])
    }

    func test_requestFeatures_withEmptyCache_savesToCache() async throws {
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
                    "productPrice": 10,
                    "_impressionId": "response-impression-id",
                    "callToAction": "Different Call To Action",
                    "actionButton": "Different Action Button"
                }
            ]
        }
        """

        let features: [any FeatureProtocol] = [
            ProductInfo(),
            RatingBox(productName: "name", productPrice: 10)
        ]

        await sut.requestFeatures(
            features,
            impressionId: fakeImpressionId
        )

        // Verify NetworkClient was called
        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled)

        XCTAssertEqual(mockFeatureCache.calls.saveItems, [
            [
                FeatureCacheItem(
                    key: FeatureKey(name: "ProductInfo", argsJson: [:]),
                    status: .on(outputsJson: ["_impressionId": "response-impression-id"])
                ),
                FeatureCacheItem(
                    key: FeatureKey(
                        name: "RatingBox",
                        argsJson: [
                            "productName": "name",
                            "productPrice": 10
                        ]
                    ),
                    status: .on(outputsJson: [
                        "product": "name",
                        "productPrice": 10,
                        "_impressionId": "response-impression-id",
                        "callToAction": "Different Call To Action",
                        "actionButton": "Different Action Button"
                    ])
                )
            ]
        ])

        // Verify session is valid
        XCTAssertFalse(mockSessionTimer.isExpired)
    }

    func test_requestFeatures_WITH_emptyCache_SHOULD_mutateFeaturesWithResponseValues() async throws {
        let feature1 = ProductDisplay(productName: "displayName", price: .init(currency: .EUR, amount: 25.99))
        let feature2 = RatingBox(productName: "name", productPrice: 10)
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
        await sut.requestFeatures(features, impressionId: requestImpressionId)

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
        let feature1 = RatingBox(productName: "name1", productPrice: 10)
        let feature2 = RatingBox(productName: "name2", productPrice: 20)
        let features: [any FeatureProtocol] = [feature1, feature2]
        mockFeatureCache.stubs.fetchKeys = { _ in
            [
                FeatureCacheItem(
                    key: FeatureKey(name: "RatingBox", argsJson: ["productName": "name1", "productPrice": 10]),
                    status: .on(outputsJson: [
                        "_impressionId": "cached _impressionId",
                        "callToAction": "response callToAction",
                        "actionButton": "response actionButton"
                    ])
                ),
                FeatureCacheItem(
                    key: FeatureKey(name: "RatingBox", argsJson: ["productName": "name2", "productPrice": 20]),
                    status: .off
                )
            ]
        }

        let requestImpressionId = "request impression id"
        let result = await sut.requestFeatures(features, impressionId: requestImpressionId)
        XCTAssertNil(result)
        XCTAssertEqual(feature1.args.productName, "name1")
        XCTAssertEqual(feature1.args.productPrice, 10)

        guard case let .on(outputs1) = feature1.status else {
            XCTFail("Expected `on` status.")
            return
        }

        XCTAssertEqual(outputs1._impressionId, requestImpressionId)

        XCTAssertEqual(feature2.args.productName, "name2")
        XCTAssertEqual(feature2.args.productPrice, 20)
        XCTAssertEqual(feature2.status, .off)
    }

    func test_requestFeatures_SHOULD_clearCacheAndRestartSessionWhenSessionExpired() async throws {
        mockSessionTimer.isExpired = true
        await sut.requestFeatures(
            [
                RatingBox(productName: "name", productPrice: 10),
                RatingBox(productName: "name", productPrice: 10)
            ],
            impressionId: fakeImpressionId
        )
        XCTAssertEqual(mockSessionTimer.calls.start.count, 1)
        XCTAssertEqual(mockFeatureCache.calls.removeAll.count, 1)
    }

    func test_requestFeatures_SHOULD_keepSessionAliveWhenSessionNotExpired() async throws {
        mockSessionTimer.isExpired = false
        await sut.requestFeatures(
            [
                RatingBox(productName: "name", productPrice: 10),
                RatingBox(productName: "name", productPrice: 10)
            ],
            impressionId: fakeImpressionId
        )
        XCTAssertGreaterThanOrEqual(mockSessionTimer.calls.keepAlive.count, 1)
        XCTAssertEqual(mockFeatureCache.calls.removeAll.count, 0)
    }

    func test_requestFeatures_SHOULD_throwErrorWhenResponseHasDifferentCount() async throws {
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

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]

        let error = await sut.requestFeatures(features)
        XCTAssertEqual(error as? CausalError, .parseFailure(message: "Requested 2 features, but received 1 impressions."))
    }

    func test_requestFeatures_SHOULD_startSSEServiceWhenRegistered() async throws {
        let feature1 = ProductDisplay(productName: "displayName", price: .init(currency: .EUR, amount: 25.99))
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]

        mockNetworkingClient.stubbedResponse = """
        {
            "registered": true,
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

        let isDone = expectation(description: #function)
        mockSSEClientFactory.stubbedClientStart = { isDone.fulfill() }
        await sut.requestFeatures(features)
        await fulfillment(of: [isDone], timeout: 0.1)
        XCTAssertEqual(mockSSEClientFactory.client?.startCallCount, 1)
    }

    func test_requestFeatures_SHOULD_notStartSSEServiceWhenNotRegistered() async throws {
        let feature1 = ProductDisplay(productName: "displayName", price: .init(currency: .EUR, amount: 25.99))
        let feature2 = RatingBox(productName: "name", productPrice: 10)
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

        let isDone = expectation(description: #function)
        isDone.isInverted = true
        mockSSEClientFactory.stubbedClientStart = { isDone.fulfill() }
        await sut.requestFeatures(features)
        await fulfillment(of: [isDone], timeout: 0.1)
        XCTAssertNil(mockSSEClientFactory.client?.startCallCount)
    }

    // MARK: signalAndWait

    func test_signalAndWait_feature_hitsCorrectEndpoint() async throws {
        let mockEvent = MockFeatureEvent()
        try await sut.signalAndWait(
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
        let mockEvent = MockSessionEvent()
        try await sut.signalAndWait(sessionEvent: mockEvent)

        XCTAssertEqual(mockNetworkingClient.receivedBaseURL, fakeImpressionServer)
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .signal)
        XCTAssertNil(mockNetworkingClient.receivedBodyJSON["impressionId"])
        XCTAssertEqual(mockNetworkingClient.receivedBodyJSON["event"] as? String, mockEvent.name)
        XCTAssertEqual(mockNetworkingClient.receivedBodyJSON["args"] as? JSONObject, mockEvent.serialized())
        XCTAssertEqual(mockNetworkingClient.receivedBodyJSON["id"] as? JSONObject, ["deviceId": "MockDeviceId"])
    }

    func test_signalAndWait_feature_throwsErrorFromNetwork() async throws {
        mockNetworkingClient.stubbedError = CausalError.fakeNetwork()
        await AsyncAssertThrowsError(
            try await sut.signalAndWait(featureEvent: (event: MockFeatureEvent(), impressionId: fakeImpressionId)),
            "client should throw error from networking client"
        )

        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled, "network client should be called")
    }

    func test_signalAndWait_session_throwsErrorFromNetwork() async throws {
        mockNetworkingClient.stubbedError = CausalError.fakeNetwork()
        await AsyncAssertThrowsError(
            try await sut.signalAndWait(sessionEvent: MockSessionEvent()),
            "client should throw error from networking client"
        )

        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled, "network client should be called")
    }

    func test_signalAndWait_feature_handlesSessionInvalidationError() async throws {
        mockNetworkingClient.stubbedError = CausalError.fakeNetwork(statusCode: 410)
        await AsyncAssertThrowsError(
            try await sut.signalAndWait(featureEvent: (event: MockFeatureEvent(), impressionId: fakeImpressionId)),
            "client should throw error from networking client"
        )

        XCTAssertEqual(mockSessionTimer.calls.invalidate.count, 2)
    }

    func test_signalAndWait_session_handlesSessionInvalidationError() async throws {
        mockNetworkingClient.stubbedError = CausalError.fakeNetwork(statusCode: 410)
        await AsyncAssertThrowsError(
            try await sut.signalAndWait(sessionEvent: MockSessionEvent()),
            "client should throw error from networking client"
        )

        XCTAssertEqual(mockSessionTimer.calls.invalidate.count, 2)
    }

    func test_signalAndWait_feature_throwsError_missingSession() async throws {
        sut.session = nil
        await AsyncAssertThrowsError(
            try await sut.signalAndWait(featureEvent: (event: MockFeatureEvent(), impressionId: fakeImpressionId))
        ) { error in
            XCTAssertEqual(error as? CausalError, CausalError.missingSession)
        }
    }

    func test_signalAndWait_session_throwsError_missingSession() async throws {
        sut.session = nil
        await AsyncAssertThrowsError(
            try await sut.signalAndWait(sessionEvent: MockSessionEvent())
        ) { error in
            XCTAssertEqual(error as? CausalError, CausalError.missingSession)
        }
    }

    func test_signalAndWait_sessionEvent_SHOULD_clearCacheAndRestartSessionWhenSessionExpired() async throws {
        mockSessionTimer.isExpired = true
        try await sut.signalAndWait(sessionEvent: MockSessionEvent())
        XCTAssertGreaterThanOrEqual(mockSessionTimer.calls.keepAlive.count, 1)
        XCTAssertEqual(mockFeatureCache.calls.removeAll.count, 1)
    }

    func test_signalAndWait_sessionEvent_SHOULD_keepSessionAliveWhenSessionNotExpired() async throws {
        mockSessionTimer.isExpired = false
        try await sut.signalAndWait(sessionEvent: MockSessionEvent())
        XCTAssertGreaterThanOrEqual(mockSessionTimer.calls.keepAlive.count, 1)
        XCTAssertEqual(mockFeatureCache.calls.removeAll.count, 0)
    }

    func test_signalAndWait_featureEvent_SHOULD_clearCacheAndRestartSessionWhenSessionExpired() async throws {
        mockSessionTimer.isExpired = true
        try await sut.signalAndWait(sessionEvent: MockSessionEvent())
        XCTAssertGreaterThanOrEqual(mockSessionTimer.calls.keepAlive.count, 1)
        XCTAssertEqual(mockFeatureCache.calls.removeAll.count, 1)
    }

    func test_signalAndWait_featureEvent_SHOULD_keepSessionAliveWhenSessionNotExpired() async throws {
        mockSessionTimer.isExpired = false
        try await sut.signalAndWait(featureEvent: (event: MockFeatureEvent(), impressionId: fakeImpressionId))
        XCTAssertGreaterThanOrEqual(mockSessionTimer.calls.keepAlive.count, 1)
        XCTAssertEqual(mockFeatureCache.calls.removeAll.count, 0)
    }

    // MARK: signal

    func test_signal_sessionEvent_SHOULD_clearCacheAndRestartSessionWhenSessionExpired() {
        let isDone = expectation(description: #function)
        mockSessionTimer.stubs.start = { isDone.fulfill() }
        mockSessionTimer.isExpired = true
        sut.signal(sessionEvent: MockSessionEvent())
        waitForExpectations(timeout: 0.1) { _ in
            XCTAssertGreaterThanOrEqual(self.mockSessionTimer.calls.keepAlive.count, 1)
            XCTAssertEqual(self.mockFeatureCache.calls.removeAll.count, 1)
        }
    }

    func test_signal_sessionEvent_SHOULD_keepSessionAliveWhenSessionNotExpired() {
        let isDone = expectation(description: #function)
        mockSessionTimer.stubs.keepAlive = { isDone.fulfill() }
        mockSessionTimer.isExpired = false
        sut.signal(sessionEvent: MockSessionEvent())
        waitForExpectations(timeout: 0.1) { _ in
            XCTAssertGreaterThanOrEqual(self.mockSessionTimer.calls.keepAlive.count, 1)
            XCTAssertEqual(self.mockFeatureCache.calls.removeAll.count, 0)
        }
    }

    func test_signal_featureEvent_SHOULD_clearCacheAndRestartSessionWhenSessionExpired() {
        let isDone = expectation(description: #function)
        mockSessionTimer.stubs.start = { isDone.fulfill() }
        mockSessionTimer.isExpired = true
        sut.signal(sessionEvent: MockSessionEvent())
        waitForExpectations(timeout: 0.1) { _ in
            XCTAssertGreaterThanOrEqual(self.mockSessionTimer.calls.keepAlive.count, 1)
            XCTAssertEqual(self.mockFeatureCache.calls.removeAll.count, 1)
        }
    }

    func test_signal_featureEvent_SHOULD_keepSessionAliveWhenSessionNotExpired() {
        let isDone = expectation(description: #function)
        mockSessionTimer.stubs.keepAlive = { isDone.fulfill() }
        mockSessionTimer.isExpired = false
        sut.signal(featureEvent: (event: MockFeatureEvent(), impressionId: fakeImpressionId))
        waitForExpectations(timeout: 0.1) { _ in
            XCTAssertGreaterThanOrEqual(self.mockSessionTimer.calls.keepAlive.count, 1)
            XCTAssertEqual(self.mockFeatureCache.calls.removeAll.count, 0)
        }
    }

    // MARK: keepAlive

    func test_keepAlive_hitsCorrectEndpoint() async throws {
        let session = Session(deviceId: "id", required: 42)
        sut.session = session
        sut.keepAlive()
        // fire-and-forget, so sleep to let call complete
        sleep(2)

        XCTAssertEqual(mockNetworkingClient.receivedBaseURL, fakeImpressionServer)
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .signal)

        XCTAssertEqual(mockNetworkingClient.receivedSession as? Session, session)
        XCTAssertEqual(mockNetworkingClient.receivedBody, try session.keys().data())
    }

    func test_keepAlive_SHOULD_clearCacheAndRestartSessionWhenSessionExpired() {
        mockSessionTimer.isExpired = true
        sut.keepAlive()
        XCTAssertGreaterThanOrEqual(mockSessionTimer.calls.keepAlive.count, 1)
        XCTAssertEqual(mockFeatureCache.calls.removeAll.count, 1)
    }

    func test_keepAlive_SHOULD_keepSessionAliveWhenSessionNotExpired() {
        mockSessionTimer.isExpired = false
        sut.keepAlive()
        XCTAssertGreaterThanOrEqual(mockSessionTimer.calls.keepAlive.count, 1)
        XCTAssertEqual(mockFeatureCache.calls.removeAll.count, 0)
    }

    // MARK: clearCache()

    func test_clearCache_SHOULD_clearTheCache() async throws {
        sut.clearCache()
        XCTAssertEqual(mockFeatureCache.calls.removeAll.count, 1)
    }

    // MARK: requestFeature

    func test_requestFeature_WITH_emptyCache_SHOULD_mutateFeaturesWithResponseValues() async throws {
        let feature = RatingBox(productName: "name", productPrice: 10)
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
        await sut.requestFeature(feature, impressionId: requestImpressionId)

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
        mockFeatureCache.stubs.fetchKeys = { _ in
            [
                FeatureCacheItem(
                    key: FeatureKey(name: "RatingBox", argsJson: ["productName": "name", "productPrice": 10]),
                    status: .on(outputsJson: [
                        "actionButton": "cached actionButton",
                        "callToAction": "cached callToAction",
                        "_impressionId": "cached _impressionId"
                    ])
                )
            ]
        }

        let feature = RatingBox(productName: "name", productPrice: 10)
        let requestImpressionId = "request impression id"
        await sut.requestFeature(feature, impressionId: requestImpressionId)

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

    func test_requestFeature_withFullCache_shouldNotCallNetwork() async throws {
        mockFeatureCache.stubs.fetchKeys = { _ in
            [
                FeatureCacheItem(
                    key: FeatureKey(name: "RatingBox", argsJson: ["productName": "name", "productPrice": 10]),
                    status: .on(outputsJson: [
                        "actionButton": "cached actionButton",
                        "callToAction": "cached callToAction",
                        "_impressionId": "cached _impressionId"
                    ])
                )
            ]
        }

        let feature = RatingBox(productName: "name", productPrice: 10)
        let requestImpressionId = "request impression id"
        await sut.requestFeature(feature, impressionId: requestImpressionId)
        XCTAssertEqual(mockNetworkingClient.sendRequestCallCount, 0)
    }

    func test_requestFeature_SHOULD_clearCacheAndRestartSessionWhenSessionExpired() async throws {
        let feature = RatingBox(productName: "name", productPrice: 10)
        mockSessionTimer.isExpired = true
        await sut.requestFeature(feature, impressionId: fakeImpressionId)
        XCTAssertEqual(mockSessionTimer.calls.start.count, 1)
        XCTAssertEqual(mockFeatureCache.calls.removeAll.count, 1)
    }

    func test_requestFeature_SHOULD_keepSessionAliveWhenSessionNotExpired() async throws {
        let feature = RatingBox(productName: "name", productPrice: 10)
        mockSessionTimer.isExpired = false
        await sut.requestFeature(feature, impressionId: fakeImpressionId)
        XCTAssertGreaterThanOrEqual(mockSessionTimer.calls.keepAlive.count, 1)
        XCTAssertEqual(mockFeatureCache.calls.removeAll.count, 0)
    }

    func test_requestFeature_SHOULD_startSSEServiceWhenRegistered() async throws {
        let feature = RatingBox(productName: "name", productPrice: 10)
        mockNetworkingClient.stubbedResponse = """
        {
            "registered": true,
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

        let isDone = expectation(description: #function)
        mockSSEClientFactory.stubbedClientStart = { isDone.fulfill() }
        await sut.requestFeature(feature)
        await fulfillment(of: [isDone], timeout: 0.1)
        XCTAssertEqual(mockSSEClientFactory.client?.startCallCount, 1)
    }

    func test_requestFeature_SHOULD_notStartSSEServiceWhenNotRegistered() async throws {
        let feature = RatingBox(productName: "name", productPrice: 10)
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

        let isDone = expectation(description: #function)
        isDone.isInverted = true
        mockSSEClientFactory.stubbedClientStart = { isDone.fulfill() }
        await sut.requestFeature(feature)
        await fulfillment(of: [isDone], timeout: 0.1)
        XCTAssertNil(mockSSEClientFactory.client?.startCallCount)
    }

    // MARK: requestCacheFill

    func test_requestCacheFill_SHOULD_makeAPICall() async throws {
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
        let features: [any FeatureProtocol] = [
            ProductInfo(),
            RatingBox(productName: "name", productPrice: 10)
        ]

        try await sut.requestCacheFill(features: features)

        // Verify NetworkClient was called
        XCTAssertTrue(mockNetworkingClient.sendRequestWasCalled)
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .features)
        // swiftlint:disable:next line_length
        XCTAssertEqual(mockNetworkingClient.receivedBodyString, "{\n  \"version\" : 2,\n  \"args\" : {\n    \"deviceId\" : \"MockDeviceId\"\n  },\n  \"reqs\" : [\n    {\n      \"name\" : \"ProductInfo\",\n      \"args\" : {\n\n      }\n    },\n    {\n      \"name\" : \"RatingBox\",\n      \"args\" : {\n        \"productName\" : \"name\",\n        \"productPrice\" : 10\n      }\n    }\n  ]\n}")
    }

    func test_requestCacheFill_SHOULD_addValuesToTheCache() async throws {
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

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]

        try await sut.requestCacheFill(features: features)

        XCTAssertEqual(mockFeatureCache.calls.saveItems, [[
            FeatureCacheItem(
                key: FeatureKey(name: "ProductInfo", argsJson: [:]),
                status: .on(outputsJson: ["_impressionId": "response-impression-id"])
            ),
            FeatureCacheItem(
                key: FeatureKey(name: "RatingBox", argsJson: ["productName": "name", "productPrice": 10]),
                status: .on(outputsJson: [
                    "product": "name",
                    "productPrice": 42,
                    "_impressionId": "response-impression-id",
                    "callToAction": "Different Call To Action",
                    "actionButton": "Different Action Button"
                ])
            )
        ]])
    }

    func test_requestCacheFill_SHOULD_notUpdateInputFeatureStatus() async throws {
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

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]

        try await sut.requestCacheFill(features: features)

        XCTAssertEqual(feature1.status, .unrequested)
        XCTAssertEqual(feature2.status, .unrequested)
    }

    func test_requestCacheFill_SHOULD_throwErrorWhenResponseHasDifferentCount() async throws {
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

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]

        await AsyncAssertThrowsError(try await sut.requestCacheFill(features: features)) { error in
            XCTAssertEqual(error as? CausalError, .parseFailure(message: "Requested 2 features, but received 1 impressions."))
        }
    }

    func test_requestCacheFill_SHOULD_startSSEServiceWhenRegistered() async throws {
        mockNetworkingClient.stubbedResponse = """
        {
            "registered": true,
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

        let isDone = expectation(description: #function)
        mockSSEClientFactory.stubbedClientStart = { isDone.fulfill() }

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]
        try await sut.requestCacheFill(features: features)
        await fulfillment(of: [isDone], timeout: 0.1)
        XCTAssertEqual(mockSSEClientFactory.client?.startCallCount, 1)
    }

    func test_requestCacheFill_SHOULD_notStartSSEServiceWhenNotRegistered() async throws {
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

        let isDone = expectation(description: #function)
        isDone.isInverted = true
        mockSSEClientFactory.stubbedClientStart = { isDone.fulfill() }

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]
        try await sut.requestCacheFill(features: features)
        await fulfillment(of: [isDone], timeout: 0.1)
        XCTAssertNil(mockSSEClientFactory.client?.startCallCount)
    }

    // MARK: addObserver

    func test_addObserver_SHOULD_addObserverToTheStore() throws {
        let handler = {}
        let feature = RatingBox(productName: "name", productPrice: 1)
        _ = try sut.addObserver(feature: feature, handler: handler)
        XCTAssertEqual(mockObserverStore.calls.add, [
            ObserverStoreItem(featureKey: try feature.key(), handler: handler)
        ])
    }

    // MARK: removeObserver

    func test_removeObserver_SHOULD_removeObserverFromTheStore() throws {
        sut.removeObserver(observerToken: "token")
        XCTAssertEqual(mockObserverStore.calls.remove, ["token"])
    }

    // MARK: defaultValues

    func test_defaultValues() async throws {
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

        sut.session = MockSession()
        let price = Price(currency: Currency.USD, amount: 10.0)
        let crossSell1 = CrossSell(productId: "1234", price: price )
        let result = await sut.requestFeature(crossSell1)
        XCTAssertNil(result)

        let body1 = try XCTUnwrap(mockNetworkingClient.receivedBodyString)
        XCTAssertTrue(body1.contains("another default"))

        try await sut.signalAndWait(featureEvent: crossSell1.event(.eventA()))
        XCTAssertTrue(mockNetworkingClient.receivedBodyString.contains("7777"))

        try await sut.signalAndWait(featureEvent: crossSell1.event(.eventA(anInt: 8_888)))
        XCTAssertTrue(mockNetworkingClient.receivedBodyString.contains("8888"))

        let crossSell2 = CrossSell(productId: "1234", price: price, withDefault: "different value")
        await sut.requestFeature(crossSell2)

        let body2 = try XCTUnwrap(mockNetworkingClient.receivedBodyString)
        XCTAssertTrue(body2.contains("different value"))
        XCTAssertFalse(body2.contains("another default"))
    }

    // MARK: SSE message handling

    func test_SSEEvent_flushCache_SHOULD_clearCache() async throws {
        mockNetworkingClient.stubbedResponse = """
        {
            "registered": true,
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

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]
        try await sut.requestCacheFill(features: features)

        let isDone = expectation(description: #function)
        mockFeatureCache.stubs.removeAll = {
            isDone.fulfill()
            return []
        }

        // Trigger a cache flush message
        mockSSEClientFactory.client!.receivedMessageHandler!(.flushCache(timestamp: .infinity))
        await fulfillment(of: [isDone], timeout: 0.1)
        XCTAssertEqual(mockFeatureCache.calls.removeAll.count, 1)
    }

    func test_SSEEvent_flushFeatures_SHOULD_clearCache() async throws {
        mockNetworkingClient.stubbedResponse = """
        {
            "registered": true,
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

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]
        try await sut.requestCacheFill(features: features)

        let isDone = expectation(description: #function)
        mockFeatureCache.stubs.removeAllNamed = { _ in
            isDone.fulfill()
            return []
        }

        // Trigger a cache flush message
        mockSSEClientFactory.client!.receivedMessageHandler!(.flushFeatures(names: ["RatingBox"]))
        await fulfillment(of: [isDone], timeout: 0.1)
        XCTAssertEqual(mockFeatureCache.calls.removeAllNamed, [["RatingBox"]])
    }

    func test_SSEEvent_flushCache_SHOULD_requestUpdatedValuesForRemovedItems() async throws {
        mockNetworkingClient.stubbedResponse = """
        {
            "registered": true,
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

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]
        try await sut.requestCacheFill(features: features)

        let cachedKeys: [FeatureKey] = [
            FeatureKey(name: "ProductInfo", argsJson: [:]),
            FeatureKey(
                name: "RatingBox",
                argsJson: [
                    "product": "name",
                    "productPrice": 42
                ]
            )
        ]

        // Simulate a full cache
        mockFeatureCache.stubs.removeAll = { cachedKeys }

        // Trigger a cache flush message
        mockSSEClientFactory.client!.receivedMessageHandler!(.flushCache(timestamp: .infinity))
        sleep(1)

        XCTAssertEqual(mockNetworkingClient.sendRequestCallCount, 2)
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .features)
        XCTAssertEqual(
            mockNetworkingClient.receivedBodyString,
            """
            {
              "version" : 2,
              "args" : {
                "deviceId" : "MockDeviceId"
              },
              "reqs" : [
                {
                  "name" : "ProductInfo",
                  "args" : {

                  }
                },
                {
                  "name" : "RatingBox",
                  "args" : {
                    "product" : "name",
                    "productPrice" : 42
                  }
                }
              ]
            }
            """
        )
    }

    func test_SSEEvent_flushFeatures_SHOULD_requestUpdatedValuesForRemovedItems() async throws {
        mockNetworkingClient.stubbedResponse = """
        {
            "registered": true,
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

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 10)
        let features: [any FeatureProtocol] = [feature1, feature2]
        try await sut.requestCacheFill(features: features)

        let cachedKeys: [FeatureKey] = [
            FeatureKey(
                name: "RatingBox",
                argsJson: [
                    "product": "name",
                    "productPrice": 42
                ]
            )
        ]

        // Simulate a full cache
        mockFeatureCache.stubs.removeAllNamed = { _ in cachedKeys }

        // Trigger a cache flush message
        mockSSEClientFactory.client!.receivedMessageHandler!(.flushFeatures(names: ["RatingBox"]))
        sleep(1)

        XCTAssertEqual(mockNetworkingClient.sendRequestCallCount, 2)
        XCTAssertEqual(mockNetworkingClient.receivedEndpoint, .features)
        XCTAssertEqual(
            mockNetworkingClient.receivedBodyString,
            """
            {
              "version" : 2,
              "args" : {
                "deviceId" : "MockDeviceId"
              },
              "reqs" : [
                {
                  "name" : "RatingBox",
                  "args" : {
                    "product" : "name",
                    "productPrice" : 42
                  }
                }
              ]
            }
            """
        )
    }

    func test_SSEEvent_flushCache_SHOULD_saveFetchedItemsInCache() async throws {
        mockNetworkingClient.stubbedResponse = """
        {
            "registered": true,
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

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 42)
        let features: [any FeatureProtocol] = [feature1, feature2]
        try await sut.requestCacheFill(features: features)

        let cachedKeys: [FeatureKey] = [
            FeatureKey(name: "ProductInfo", argsJson: [:]),
            FeatureKey(
                name: "RatingBox",
                argsJson: [
                    "product": "name",
                    "productPrice": 42
                ]
            )
        ]

        // Simulate a full cache
        mockFeatureCache.stubs.removeAll = { cachedKeys }

        let isDone = expectation(description: #function)
        mockFeatureCache.stubs.saveItems = { _ in isDone.fulfill() }

        // Trigger a cache flush message
        mockSSEClientFactory.client!.receivedMessageHandler!(.flushCache(timestamp: .infinity))
        await fulfillment(of: [isDone], timeout: 0.1)
        XCTAssertEqual(
            mockFeatureCache.calls.saveItems[1],
            [
                FeatureCacheItem(
                    key: FeatureKey(name: "ProductInfo", argsJson: [:]),
                    status: .on(outputsJson: ["_impressionId": "response-impression-id"])
                ),
                FeatureCacheItem(
                    key: FeatureKey(
                        name: "RatingBox",
                        argsJson: [
                            "product": "name",
                            "productPrice": 42
                        ]
                    ),
                    status: .on(outputsJson: [
                        "product": "name",
                        "productPrice": 42,
                        "_impressionId": "response-impression-id",
                        "callToAction": "Different Call To Action",
                        "actionButton": "Different Action Button"
                    ])
                )
            ]
        )
    }

    func test_SSEEvent_flushFeatures_SHOULD_saveFetchedItemsInCache() async throws {
        mockNetworkingClient.stubbedResponse = """
        {
            "registered": true,
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

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 42)
        let features: [any FeatureProtocol] = [feature1, feature2]
        try await sut.requestCacheFill(features: features)

        mockNetworkingClient.stubbedResponse = """
        {
            "registered": true,
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

        let cachedKeys: [FeatureKey] = [
            FeatureKey(
                name: "RatingBox",
                argsJson: [
                    "product": "name",
                    "productPrice": 42
                ]
            )
        ]

        // Simulate a full cache
        mockFeatureCache.stubs.removeAllNamed = { _ in cachedKeys }

        let isDone = expectation(description: #function)
        mockFeatureCache.stubs.saveItems = { _ in isDone.fulfill() }

        // Trigger a cache flush message
        mockSSEClientFactory.client!.receivedMessageHandler!(.flushFeatures(names: ["RatingBox"]))
        await fulfillment(of: [isDone], timeout: 0.1)
        XCTAssertEqual(
            mockFeatureCache.calls.saveItems[1],
            [
                FeatureCacheItem(
                    key: FeatureKey(
                        name: "RatingBox",
                        argsJson: [
                            "product": "name",
                            "productPrice": 42
                        ]
                    ),
                    status: .on(outputsJson: [
                        "product": "name",
                        "productPrice": 42,
                        "_impressionId": "response-impression-id",
                        "callToAction": "Different Call To Action",
                        "actionButton": "Different Action Button"
                    ])
                )
            ]
        )
    }

    func test_SSEEvent_flushCache_SHOULD_callObserver() async throws {
        mockNetworkingClient.stubbedResponse = """
        {
            "registered": true,
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

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 42)
        let features: [any FeatureProtocol] = [feature1, feature2]
        try await sut.requestCacheFill(features: features)

        let cachedKeys: [FeatureKey] = [
            FeatureKey(name: "ProductInfo", argsJson: [:]),
            FeatureKey(
                name: "RatingBox",
                argsJson: [
                    "product": "name",
                    "productPrice": 42
                ]
            )
        ]

        let isDone = expectation(description: #function)
        let handler = {
            isDone.fulfill()
        }

        // Simulate a full cache
        mockFeatureCache.stubs.removeAll = { cachedKeys }

        // Add an observer
        mockObserverStore.stubs.fetch = { _ in [handler] }

        // Trigger a cache flush message
        mockSSEClientFactory.client!.receivedMessageHandler!(.flushCache(timestamp: .infinity))

        await fulfillment(of: [isDone], timeout: 0.1)
    }

    func test_SSEEvent_flushFeatures_SHOULD_callObserver() async throws {
        mockNetworkingClient.stubbedResponse = """
        {
            "registered": true,
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

        let feature1 = ProductInfo()
        let feature2 = RatingBox(productName: "name", productPrice: 42)
        let features: [any FeatureProtocol] = [feature1, feature2]
        try await sut.requestCacheFill(features: features)

        mockNetworkingClient.stubbedResponse = """
        {
            "registered": true,
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

        let cachedKeys: [FeatureKey] = [
            FeatureKey(
                name: "RatingBox",
                argsJson: [
                    "product": "name",
                    "productPrice": 42
                ]
            )
        ]

        let isDone = expectation(description: #function)
        let handler = {
            isDone.fulfill()
        }

        // Simulate a full cache
        mockFeatureCache.stubs.removeAllNamed = { _ in cachedKeys }

        // Add an observer
        mockObserverStore.stubs.fetch = { _ in [handler] }

        // Trigger a cache flush message
        mockSSEClientFactory.client!.receivedMessageHandler!(.flushFeatures(names: ["RatingBox"]))

        await fulfillment(of: [isDone], timeout: 0.1)
    }
}

private extension JSONObject {
    func data() throws -> Data {
        try JSONSerialization.data(withJSONObject: self, options: [.sortedKeys, .prettyPrinted])
    }
}
