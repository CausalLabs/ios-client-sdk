//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

final class EmptyFDLTests: XCTestCase {
    func test() {
        // The empty FDL should still generate an empty, default Session object.
        // This test is just a place holder to verify that the FDL was generated.
        let session = Session(deviceId: "id")
        XCTAssertNotNil(session)
    }
}
