//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import Foundation

final class MockSSEClientFactory: SSEClientFactoryProtocol {
    var client: MockSSEClient?

    var stubbedClientStart: () -> Void = { }

    var stubbedClientStop: () -> Void = { }

    var createClientCallCount = 0

    func createClient(impressionServer: URL,
                      session: any SessionProtocol,
                      messageHandler: @escaping SSEMessageHandler
    ) -> SSEClientProtocol {
        self.createClientCallCount += 1

        let client = MockSSEClient(
            impressionServer: impressionServer,
            session: session,
            messageHandler: messageHandler
        )
        client.stubbedStart = self.stubbedClientStart
        client.stubbedStop = self.stubbedClientStop
        self.client = client
        return client
    }
}

final class MockSSEClient: SSEClientProtocol {

    var receivedImpressionServer: URL?
    var receivedSession: (any SessionProtocol)?
    var receivedMessageHandler: SSEMessageHandler?

    init(
        impressionServer: URL,
        session: any SessionProtocol,
        messageHandler: @escaping SSEMessageHandler
    ) {
        self.receivedImpressionServer = impressionServer
        self.receivedSession = session
        self.receivedMessageHandler = messageHandler
    }

    // MARK: SSEClientProtocol

    var isStarted = false

    var stubbedStart: () -> Void = { }
    var startCallCount = 0
    func start() {
        self.startCallCount += 1
        self.stubbedStart()
    }

    var stubbedStop: () -> Void = { }
    var stopCallCount = 0
    func stop() {
        self.stopCallCount += 1
        self.stubbedStop()
    }
}
