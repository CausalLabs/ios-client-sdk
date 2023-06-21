//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

extension URLRequest {
    init(
        impressionServer: URL,
        endpoint: CausalEndpoint,
        session: any SessionProtocol,
        headers: [String: String] = [:],
        body: Data? = nil
    ) throws {
        self.init(url: impressionServer.appendingPathComponent(endpoint.path))
        self.httpMethod = "POST"

        self.setHeaders([
            "User-Agent": "Causal iOS Client",
            "Accept": "application/json,text/plain",
            "Content-Type": "application/json"
        ])

        let sessionKeys = try session.keys()
        var sessionHeaders = [String: String]()
        for (_key, _val) in sessionKeys {
            let key = "x-causal-\(_key)".lowercased()
            sessionHeaders[key] = _val as? String
        }
        self.setHeaders(sessionHeaders)

        self.setHeaders(headers)
        self.httpBody = body
    }

    mutating func setHeaders(_ headers: [String: String]) {
        guard !headers.isEmpty else { return }

        for (key, value) in headers {
            self.setValue(value, forHTTPHeaderField: key)
        }
    }
}
