//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

final class CausalEndpointTests: XCTestCase {

    func test_path() {
        XCTAssertEqual(CausalEndpoint.features.path, "features")
        XCTAssertEqual(CausalEndpoint.signal.path, "signal")
    }
}
