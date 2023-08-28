//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation
import LDSwiftEventSource

final class CausalEventHandler: EventHandler {
    private let messageHandler: SSEMessageHandler

    private let logger: Logger

    // MARK: Init

    init(messageHandler: @escaping SSEMessageHandler, logger: Logger = .shared) {
        self.messageHandler = messageHandler
        self.logger = logger
    }

    // MARK: EventHandler

    func onOpened() {
        self.logger.info("SSE connection opened")
    }

    func onClosed() {
        self.logger.info("SSE connection closed")
    }

    func onMessage(eventType: String, messageEvent: MessageEvent) {
        self.logger.info("[SSE] type: \(eventType), message: \(messageEvent)")

        guard let message = SSEMessage(eventType: eventType, messageEvent: messageEvent) else {
            self.logger.warning("[SSE] unable to parse event type: \(eventType)")
            return
        }

        self.messageHandler(message)
    }

    func onComment(comment: String) {
        self.logger.info("[SSE] Comment: \(comment)")
    }

    func onError(error: Error) {
        self.logger.error("[SSE] Error", error: error)
    }
}
