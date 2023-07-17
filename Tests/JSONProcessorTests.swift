//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

final class JSONProcessorTests: XCTestCase {

    let jsonProcessor = JSONProcessor()

    func test_encode_requestFeatures() async throws {
        let session = Session(deviceId: fakeDeviceId, required: 0)
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0
        )
        ratingBox.impressionIds = [fakeImpressionId]

        let jsonData = try self.jsonProcessor.encodeRequestFeatures(
            features: [ratingBox],
            session: session,
            impressionId: fakeImpressionId
        )

        let expectedJSON = """
        {
          "args" : {
            "deviceId" : "\(fakeDeviceId)",
            "required" : 0,
            "withDefault" : "a default value"
          },
          "impressionId" : "\(fakeImpressionId)",
          "reqs" : [
            {
              "name" : "RatingBox",
              "args" : {
                "productName" : "name",
                "productPrice" : 10
              }
            }
          ]
        }
        """

        XCTAssertEqual(jsonData.jsonString(), expectedJSON)
    }

    func test_encode_requestFeatures_usingStaticSessionConstructor() async throws {
        let session = Session.fromDeviceId(fakeDeviceId)
        let ratingBox = RatingBox(
            productName: "name",
            productPrice: 10.0
        )
        ratingBox.impressionIds = [fakeImpressionId]

        let jsonData = try self.jsonProcessor.encodeRequestFeatures(
            features: [ratingBox],
            session: session,
            impressionId: fakeImpressionId
        )

        let expectedJSON = """
        {
          "args" : {
            "deviceId" : "\(fakeDeviceId)"
          },
          "impressionId" : "\(fakeImpressionId)",
          "reqs" : [
            {
              "name" : "RatingBox",
              "args" : {
                "productName" : "name",
                "productPrice" : 10
              }
            }
          ]
        }
        """

        XCTAssertEqual(jsonData.jsonString(), expectedJSON)
    }

    func test_encode_signalEvent() async throws {
        let session = Session(deviceId: fakeDeviceId, required: 0)
        let event = RatingBox.Rating(stars: 5)

        let jsonData = try self.jsonProcessor.encodeSignalEvent(
            event: event,
            session: session,
            impressionId: fakeImpressionId
        )

        let expectedJSON = """
        {
          "args" : {
            "stars" : 5
          },
          "event" : "Rating",
          "feature" : "RatingBox",
          "id" : {
            "deviceId" : "\(fakeDeviceId)"
          },
          "impressionId" : "\(fakeImpressionId)"
        }
        """

        XCTAssertEqual(jsonData.jsonString(), expectedJSON)
    }

    func test_encode_SignalCachedFeatures() async throws {
        let session = Session(deviceId: fakeDeviceId, required: 0)
        let ratingBox = RatingBox(productName: "product", productPrice: 10)
        ratingBox.impressionIds = ["old-impression-id"]

        let jsonData = try self.jsonProcessor.encodeSignalCachedFeatures(
            features: [ratingBox],
            session: session,
            impressionId: fakeImpressionId
        )

        let expectedJSON = """
        {
          "id" : {
            "deviceId" : "\(fakeDeviceId)"
          },
          "impressions" : {
            "RatingBox" : {
              "impression" : "old-impression-id",
              "newImpression" : "\(fakeImpressionId)"
            }
          }
        }
        """

        XCTAssertEqual(jsonData.jsonString(), expectedJSON)
    }

    func test_encode_keepAlive() async throws {
        let session = Session(deviceId: fakeDeviceId, required: 0)

        let jsonData = try self.jsonProcessor.encodeKeepAlive(session: session)

        let expectedJSON = """
        {
          "deviceId" : "\(fakeDeviceId)"
        }
        """

        XCTAssertEqual(jsonData.jsonString(), expectedJSON)
    }

    func test_decodeData() async throws {
        let validData = String("{ \"status\" : \"ok\" }").data(using: .utf8)!
        let json = try self.jsonProcessor.decode(data: validData)
        XCTAssertEqual(json, ["status": "ok"])

        let corruptData = Data()
        XCTAssertThrowsError(try self.jsonProcessor.decode(data: corruptData))
    }

    func test_decodeRequestFeatures() async throws {
        let json = """
        {
          "session": {
             "deviceId" : "\(fakeDeviceId)",
             "sessionId" : "89096d5b-fd42-4dd5-bec3-faa31579d388",
             "startTime" : 1684278833067
          },
          "impressions": [
             {
               "impressionIds" : [
                 "\(fakeImpressionId)"
               ],
               "callToAction" : "TRY THIS",
               "actionButton": "New Button"
             }
          ]
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))

        let initialSession = Session(deviceId: "deviceId", required: 0)
        let initialRatingBox = RatingBox(
            productName: "product name",
            productPrice: 0
        )

        let (_session, features) = try self.jsonProcessor.decodeRequestFeatures(
            response: data,
            features: [initialRatingBox],
            session: initialSession
        )
        let ratingBox = try XCTUnwrap(features.first as? RatingBox)

        XCTAssertEqual(features.count, 1)
        let session = try XCTUnwrap(_session as? Session)
        XCTAssertEqual(session.deviceId, "deviceId")
        XCTAssertEqual(ratingBox.productName, "product name")
        XCTAssertEqual(ratingBox.productPrice, 0)
        XCTAssertEqual(ratingBox.impressionIds, [fakeImpressionId])
        XCTAssertTrue(ratingBox.isActive)
        XCTAssertEqual(ratingBox.callToAction, "TRY THIS")
        XCTAssertEqual(ratingBox.actionButton, "New Button")
    }
}
