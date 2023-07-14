//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

extension URLRequest {
    static var defaultHeaders: [String: String] {
        [
            "User-Agent": "Causal iOS Client"
        ]
    }

    init(
        impressionServer: URL,
        endpoint: CausalEndpoint,
        session: any SessionProtocol,
        headers: [String: String] = [:],
        body: Data? = nil
    ) throws {
        self.init(url: impressionServer.appendingPathComponent(endpoint.path))
        self.httpMethod = "POST"
        self.httpBody = body
        self.setHeaders([
            "Accept": "application/json,text/plain",
            "Content-Type": "application/json"
        ])
        self.setHeaders(Self.defaultHeaders)
        self.setHeaders(try session.headers())
        self.setHeaders(headers)
    }

    mutating func setHeaders(_ headers: [String: String]) {
        guard !headers.isEmpty else { return }

        for (key, value) in headers {
            self.setValue(value, forHTTPHeaderField: key)
        }
    }
}
