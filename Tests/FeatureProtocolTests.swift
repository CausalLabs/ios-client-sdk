//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

final class FeatureProtocolTests: XCTestCase {

    func test_init() {
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0
        )

        XCTAssertEqual(ratingBox.status, .unrequested)
        XCTAssertEqual(ratingBox.name, "RatingBox")
        XCTAssertEqual(ratingBox.args.productName, "name")
        XCTAssertEqual(ratingBox.args.productPrice, 10.0)
        XCTAssertNil(ratingBox.args.productDescription)
    }

    func test_key() {
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0
        )

        XCTAssertEqual(
            try ratingBox.key(),
            FeatureKey(name: "RatingBox", argsJson: ["productName": "name", "productPrice": 10])
        )

        let productDisplay = ProductDisplay(productName: "name", price: Price(currency: .USD, amount: 25))
        XCTAssertEqual(
            try productDisplay.key(),
            FeatureKey(
                name: "ProductDisplay",
                argsJson: [
                    "productName": "name",
                    "price": [
                        "currency": "USD",
                        "amount": 25
                    ] as JSONObject
                ]
            )
        )
    }

    func test_key_withNoArgs() {
        let productInfo = ProductInfo()
        XCTAssertEqual(
            try productInfo.key(),
            FeatureKey(name: "ProductInfo", argsJson: [:])
        )
    }

    func test_args() throws {
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0,
            productDescription: "description"
        )

        let expectedJSON: JSONObject = [
            "productName": "name",
            "productPrice": 10.0,
            "productDescription": "description"
        ]

        XCTAssertEqual(try ratingBox.args.encodeToJSONObject(), expectedJSON)
    }

    func test_args_withNil() throws {
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0,
            productDescription: nil
        )

        let expectedJSON: JSONObject = [
            "productName": "name",
            "productPrice": 10.0
        ]

        XCTAssertEqual(try ratingBox.args.encodeToJSONObject(), expectedJSON)
    }

    func test_update_SHOULD_notUpdateWithOnRequest_invalidJSON() throws {
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0,
            productDescription: "description"
        )
        XCTAssertThrowsError(try ratingBox.update(request: .on(outputJson: JSONObject(), impressionId: nil)), "Invalid JSON should throw")
        XCTAssertEqual(ratingBox.status, .unrequested)
    }

    func test_update_SHOULD_updateWithOnRequest_validJSON_nilImpressionId() throws {
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0,
            productDescription: "description"
        )

        let updatedJSON: JSONObject = [
            "callToAction": "New Call",
            "actionButton": "New Button",
            "_impressionId": "encode_impression_id"
        ]

        try ratingBox.update(request: .on(outputJson: updatedJSON, impressionId: nil))
        if case let .on(outputs) = ratingBox.status {
            XCTAssertEqual(outputs.callToAction, "New Call")
            XCTAssertEqual(outputs.actionButton, "New Button")
            XCTAssertEqual(outputs._impressionId, "encode_impression_id")
        } else {
            XCTFail("expected a status of `on`.")
        }
    }

    func test_update_SHOULD_updateWithOnRequest_validJSON_impressionId() throws {
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0,
            productDescription: "description"
        )

        let updatedJSON: JSONObject = [
            "callToAction": "New Call",
            "actionButton": "New Button",
            "_impressionId": "encoded_impression_id"
        ]

        try ratingBox.update(request: .on(outputJson: updatedJSON, impressionId: "new_impression_id"))
        if case let .on(outputs) = ratingBox.status {
            XCTAssertEqual(outputs.callToAction, "New Call")
            XCTAssertEqual(outputs.actionButton, "New Button")
            XCTAssertEqual(outputs._impressionId, "new_impression_id")
        } else {
            XCTFail("expected a status of `on`.")
        }
    }

    func test_update_SHOULD_updateWithOffRequest() throws {
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0,
            productDescription: "description"
        )
        try ratingBox.update(request: .off)
        XCTAssertEqual(ratingBox.status, .off)
    }

    func test_update_SHOULD_updateWithDefaultStatusOn() throws {
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0,
            productDescription: "description"
        )
        try ratingBox.update(request: .defaultStatus)
        XCTAssertEqual(ratingBox.status, .on(outputs: .defaultValues))
    }

    func test_update_SHOULD_updateWithDefaultStatusOff() throws {
        let crossSell = CrossSellDefaultOff(productId: "123")
        try crossSell.update(request: .defaultStatus)
        XCTAssertEqual(crossSell.status, .off)
    }

    func test_event_SHOULD_bundleInputEventWithImpressionId() throws {
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0,
            productDescription: "description"
        )

        let updatedJSON: JSONObject = [
            "callToAction": "New Call",
            "actionButton": "New Button",
            "_impressionId": "encoded_impression_id"
        ]

        // Update the feature to have an active status
        try ratingBox.update(request: .on(outputJson: updatedJSON, impressionId: "new_impression_id"))

        let result = ratingBox.event(.rating(stars: 3))
        XCTAssertEqual(try result?.event.serialized(), try RatingBox.Rating(stars: 3).serialized())
        XCTAssertEqual(result?.impressionId, "new_impression_id")
    }
}
