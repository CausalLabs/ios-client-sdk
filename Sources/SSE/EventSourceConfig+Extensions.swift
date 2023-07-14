//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation
import LDSwiftEventSource

extension EventSource.Config {
    init(
        impressionServer: URL,
        eventHandler: CausalEventHandler,
        session: any SessionProtocol
    ) {
        let baseURL = impressionServer.appendingPathComponent(CausalEndpoint.sse.path)
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "id", value: session.persistentId)]
        guard let url = components?.url else {
            fatalError("Invalid URL: \(String(describing: components))")
        }

        self.init(handler: eventHandler, url: url)

        var headers = (try? session.headers()) ?? [:]
        URLRequest.defaultHeaders.forEach { key, value in
            headers[key] = value
        }
        self.headers = headers
    }
}
