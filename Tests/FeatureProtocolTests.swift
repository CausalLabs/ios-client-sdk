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
        XCTAssertEqual(ratingBox.name, "RatingBox")
        XCTAssertTrue(ratingBox.isActive)
        XCTAssertEqual(ratingBox.callToAction, "Rate this product!")
        XCTAssertEqual(ratingBox.actionButton, "Send Review")

        XCTAssertEqual(ratingBox.productName, "name")
        XCTAssertEqual(ratingBox.productPrice, 10.0)
        XCTAssertNil(ratingBox.productDescription)
    }

    func test_id() {
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0
        )

        XCTAssertEqual(
            ratingBox.id,
            #"{"args":{"productName":"name","productPrice":10},"name":"RatingBox"}"#
        )

        let productDisplay = ProductDisplay(productName: "name", price: Price(currency: .USD, amount: 25))
        XCTAssertEqual(
            productDisplay.id,
            #"{"args":{"price":{"amount":25,"currency":"USD"},"productName":"name"},"name":"ProductDisplay"}"#
        )
    }

    func test_id_withNoArgs() {
        let productInfo = ProductInfo()
        XCTAssertEqual(
            productInfo.id,
            #"{"args":{},"name":"ProductInfo"}"#
        )
    }

    func test_args() throws {
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0,
            productDescription: "description"
        )
        ratingBox.impressionIds = [fakeImpressionId]

        let expectedJSON: JSONObject = [
            "productName": "name",
            "productPrice": 10.0,
            "productDescription": "description"
        ]

        XCTAssertEqual(try ratingBox.args(), expectedJSON)
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

        XCTAssertEqual(try ratingBox.args(), expectedJSON)
    }

    func test_updateFromJSON() throws {
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0,
            productDescription: "description"
        )
        ratingBox.impressionIds = [fakeImpressionId]

        XCTAssertThrowsError(try ratingBox.updateFrom(json: JSONObject()), "Invalid JSON should throw")

        XCTAssertEqual(ratingBox.productName, "name")
        XCTAssertEqual(ratingBox.productPrice, 10.0)
        XCTAssertEqual(ratingBox.productDescription, "description")
        XCTAssertEqual(ratingBox.impressionIds, [fakeImpressionId])
        XCTAssertEqual(ratingBox.callToAction, "Rate this product!")
        XCTAssertEqual(ratingBox.actionButton, "Send Review")

        let newImpressionId = UUID().uuidString
        let updatedJSON: JSONObject = [
            "callToAction": "New Call",
            "actionButton": "New Button",
            "impressionIds": [
                fakeImpressionId,
                newImpressionId
            ]
        ]

        try ratingBox.updateFrom(json: updatedJSON)
        XCTAssertEqual(ratingBox.impressionIds, [fakeImpressionId, newImpressionId])
        XCTAssertEqual(ratingBox.callToAction, "New Call")
        XCTAssertEqual(ratingBox.actionButton, "New Button")
    }

    func test_copy_withNewImpressionId() throws {
        let original = RatingBox(productName: "name", productPrice: 10, productDescription: "description")
        original.impressionIds = ["aaa-bbb-ccc"]

        let copy = original.copy(newImpressionId: "xxx-yyy-zzz")
        XCTAssertNotEqual(copy, original)

        XCTAssertEqual(original.impressionIds, ["aaa-bbb-ccc"])
        XCTAssertEqual(copy.impressionIds, ["xxx-yyy-zzz"])

        XCTAssertEqual(try copy.args(), try original.args())
    }
}
