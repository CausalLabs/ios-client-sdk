//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

extension Data {
    func jsonString() -> String {
        String(decoding: self, as: UTF8.self)
    }
}
