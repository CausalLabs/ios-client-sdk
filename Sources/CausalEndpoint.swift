//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

enum CausalEndpoint: String {
    case features
    case signal
    case sse

    var path: String {
        self.rawValue
    }
}
