//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation
import LDSwiftEventSource

final class SSEClient: SSEClientProtocol {
    private let eventSource: EventSource
    private(set) var isStarted = false
    let impressionServer: URL
    let persistentId: DeviceId?

    init(
        impressionServer: URL,
        session: any SessionProtocol,
        messageHandler: @escaping SSEMessageHandler
    ) {
        let eventHandler = CausalEventHandler(messageHandler: messageHandler)
        let config = EventSource.Config(
            impressionServer: impressionServer,
            eventHandler: eventHandler,
            session: session
        )
        self.eventSource = EventSource(config: config)
        self.impressionServer = impressionServer
        self.persistentId = session.persistentId
    }

    func start() {
        guard !isStarted else { return }

        eventSource.start()
        isStarted = true
    }

    func stop() {
        guard isStarted else { return }

        eventSource.stop()
        isStarted = false
    }
}
