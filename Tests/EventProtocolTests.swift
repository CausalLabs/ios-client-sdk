//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

final class EventProtocolTests: XCTestCase {

    func test_init() {
        let ratingEvent = RatingBox.Event.Rating(stars: 5)
        XCTAssertEqual(ratingEvent.name, "Rating")
        XCTAssertEqual(ratingEvent.featureName, "RatingBox")
        XCTAssertEqual(ratingEvent.stars, 5)
    }

    func test_serialized() {
        let ratingEvent = RatingBox.Event.Rating(stars: 5)

        let expectedJSON: JSONObject = [
            "stars": 5
        ]

        XCTAssertEqual(try ratingEvent.serialized(), expectedJSON)
    }
}
