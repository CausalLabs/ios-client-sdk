//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

final class SSETests: XCTestCase {

    func test_initialStartSSE_stopSSE() async throws {
        let session = MockSession()

        let mockFactory = MockSSEClientFactory()
        XCTAssertNil(mockFactory.client)

        let client = CausalClient.fake(
            featureCache: await FeatureCache(),
            session: session,
            mockSSEClientFactory: mockFactory
        )

        XCTAssertNil(mockFactory.client, "client should still be nil after initialization")

        let expectationStart = self.expectation(description: "startSSE")
        mockFactory.stubbedClientStart = {
            expectationStart.fulfill()
        }

        let expectationStop = self.expectation(description: "stopSSE")
        mockFactory.stubbedClientStop = {
            expectationStop.fulfill()
        }

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
        let client = CausalClient.fake(
            featureCache: await FeatureCache(),
            mockSSEClientFactory: mockFactory
        )

        XCTAssertNil(mockFactory.client, "client should still be nil after initialization")

        let expectationStart = self.expectation(description: "startSSE")
        mockFactory.stubbedClientStart = {
            expectationStart.fulfill()
        }

        let expectationStop = self.expectation(description: "stopSSE")
        mockFactory.stubbedClientStop = {
            expectationStop.fulfill()
        }

        client.startSSE()

        // simulate restart (after session gets updated)
        let expectationRestart = self.expectation(description: "restartSSE")
        mockFactory.stubbedClientStart = {
            expectationRestart.fulfill()
        }

        client.startSSE()

        await self.fulfillment(
            of: [expectationStart, expectationStop, expectationRestart],
            timeout: 1,
            enforceOrder: true
        )
    }

    func test_handleEvent_flushCache() async throws {
        let cache = await FeatureCache()
        let mockFactory = MockSSEClientFactory()
        let client = CausalClient.fake(
            featureCache: cache,
            mockSSEClientFactory: mockFactory
        )
        let features: [any FeatureProtocol] = [
            MockFeature(),
            RatingBox(productName: "name", productPrice: 10)
        ]
        try await client.requestCacheFill(features: features)
        let count = await cache.count
        XCTAssertEqual(count, 2)

        client.startSSE()
        let messageHandler = try XCTUnwrap(mockFactory.client?.receivedMessageHandler)
        let flushMessage = SSEMessage.flushCache(timestamp: 0)
        messageHandler(flushMessage)

        // the message handler clears the cache async, so we can't await
        // sleep to let call complete
        sleep(2)
        let isEmpty = await cache.isEmpty
        XCTAssertTrue(isEmpty)
    }

    func test_handleEvent_flushFeatures() async throws {
        let cache = await FeatureCache()
        let mockFactory = MockSSEClientFactory()
        let client = CausalClient.fake(
            featureCache: cache,
            mockSSEClientFactory: mockFactory
        )
        let features: [any FeatureProtocol] = [
            MockFeature(),
            RatingBox(productName: "name1", productPrice: 11),
            RatingBox(productName: "name2", productPrice: 22)
        ]
        try await client.requestCacheFill(features: features)
        let initialCount = await cache.count
        XCTAssertEqual(initialCount, 3)

        client.startSSE()
        let messageHandler = try XCTUnwrap(mockFactory.client?.receivedMessageHandler)
        let flushMessage = SSEMessage.flushFeatures(names: ["RatingBox"])
        messageHandler(flushMessage)

        // the message handler clears the cache async, so we can't await
        // sleep to let call complete
        sleep(2)
        let count = await cache.count
        XCTAssertEqual(count, 1)
    }
}
