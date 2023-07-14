//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation
import LDSwiftEventSource

typealias SSEMessageHandler = (SSEMessage) -> Void

protocol SSEClientProtocol: AnyObject {
    var isStarted: Bool { get }

    func start()

    func stop()
}

final class SSEClient: SSEClientProtocol {
    private let eventSource: EventSource

    private(set) var isStarted = false

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
    }

    func start() {
        guard !self.isStarted else { return }

        self.eventSource.start()
        self.isStarted = true
    }

    func stop() {
        guard self.isStarted else { return }

        self.eventSource.stop()
        self.isStarted = false
    }
}
