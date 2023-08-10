//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

final class SSETests: XCTestCase {

    func test_initialStartSSE_stopSSE() async throws {
        let session = MockSession()

        let mockFactory = MockSSEClientFactory()
        let expectationStart = self.expectation(description: "startSSE")
        mockFactory.stubbedClientStart = {
            expectationStart.fulfill()
        }
        let expectationStop = self.expectation(description: "stopSSE")
        mockFactory.stubbedClientStop = {
            expectationStop.fulfill()
        }
        XCTAssertNil(mockFactory.client)

        let client = CausalClient.fake(
            featureCache: FeatureCache(),
            session: session,
            mockSSEClientFactory: mockFactory
        )

        XCTAssertNotNil(mockFactory.client, "client should get initialized when setting session")

        client.startSSE()

        let mockSSEClient = try XCTUnwrap(mockFactory.client)
        XCTAssertEqual(mockSSEClient.receivedImpressionServer, client.impressionServer)
        XCTAssertEqual(mockSSEClient.receivedSession as? MockSession, session)
        XCTAssertNotNil(mockSSEClient.receivedMessageHandler)

        client.stopSSE()

        await self.fulfillment(
            of: [expectationStart, expectationStop],
            timeout: 1,
            enforceOrder: true
        )
    }

    func test_restartSSE() async throws {
        let mockFactory = MockSSEClientFactory()
        let expectationStart = self.expectation(description: "startSSE")
        mockFactory.stubbedClientStart = {
            expectationStart.fulfill()
        }
        let expectationStop = self.expectation(description: "stopSSE")
        mockFactory.stubbedClientStop = {
            expectationStop.fulfill()
        }

        let client = CausalClient.fake(
            featureCache: FeatureCache(),
            mockSSEClientFactory: mockFactory
        )
        XCTAssertNotNil(mockFactory.client, "client should get initialized when setting session")

        client.startSSE()

        // simulate restart (after session gets updated)
        let expectationRestart = self.expectation(description: "restartSSE")
        mockFactory.stubbedClientStart = {
            expectationRestart.fulfill()
        }
        client.session = MockSession(deviceId: "new-session-id")

        await self.fulfillment(
            of: [expectationStart, expectationStop, expectationRestart],
            timeout: 1,
            enforceOrder: true
        )
    }

    func test_handleEvent_flushCache() async throws {
        let cache = FeatureCache()
        let mockFactory = MockSSEClientFactory()
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
                    "_impressionId": "response-impression-id"
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

        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient,
            mockSSEClientFactory: mockFactory
        )
        let features: [any FeatureProtocol] = [
            ProductInfo(),
            RatingBox(productName: "name", productPrice: 10)
        ]
        try await client.requestCacheFill(features: features)
        let count = cache.count
        XCTAssertEqual(count, 2)

        client.startSSE()
        let messageHandler = try XCTUnwrap(mockFactory.client?.receivedMessageHandler)
        let flushMessage = SSEMessage.flushCache(timestamp: 0)
        messageHandler(flushMessage)

        // the message handler clears the cache async, so we can't await
        // sleep to let call complete
        sleep(2)
        let isEmpty = cache.isEmpty
        XCTAssertTrue(isEmpty)
    }

    func test_handleEvent_flushFeatures() async throws {
        let cache = FeatureCache()
        let mockFactory = MockSSEClientFactory()
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
                    "_impressionId": "response-impression-id"
                },
                {
                    "product": "name1",
                    "productPrice": 11,
                    "_impressionId": "response-impression-id",
                    "callToAction": "Different Call To Action",
                    "actionButton": "Different Action Button"
                },
                {
                    "product": "name2",
                    "productPrice": 22,
                    "_impressionId": "response-impression-id",
                    "callToAction": "Different Call To Action",
                    "actionButton": "Different Action Button"
                }
            ]
        }
        """
        let client = CausalClient.fake(
            featureCache: cache,
            mockNetworkingClient: mockNetworkingClient,
            mockSSEClientFactory: mockFactory
        )
        let features: [any FeatureProtocol] = [
            ProductInfo(),
            RatingBox(productName: "name1", productPrice: 11),
            RatingBox(productName: "name2", productPrice: 22)
        ]
        try await client.requestCacheFill(features: features)
        XCTAssertEqual(cache.count, 3)

        client.startSSE()
        let messageHandler = try XCTUnwrap(mockFactory.client?.receivedMessageHandler)
        let flushMessage = SSEMessage.flushFeatures(names: ["RatingBox"])
        messageHandler(flushMessage)

        // the message handler clears the cache async, so we can't await
        // sleep to let call complete
        sleep(2)
        XCTAssertEqual(cache.count, 1)
    }
}
