//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

extension HTTPURLResponse {
    var isError: Bool {
        self.statusCode >= 400
    }
}

extension URLResponse {
    var httpResponse: HTTPURLResponse? {
        self as? HTTPURLResponse
    }
}
