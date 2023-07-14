//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

protocol SSEClientFactoryProtocol {
    func createClient(impressionServer: URL,
                      session: any SessionProtocol,
                      messageHandler: @escaping SSEMessageHandler) -> SSEClientProtocol
}

struct SSEClientFactory: SSEClientFactoryProtocol {
    func createClient(
        impressionServer: URL,
        session: any SessionProtocol,
        messageHandler: @escaping SSEMessageHandler
    ) -> SSEClientProtocol {
        SSEClient(
            impressionServer: impressionServer,
            session: session,
            messageHandler: messageHandler
        )
    }
}
