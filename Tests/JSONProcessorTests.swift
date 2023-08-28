//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import XCTest

private extension JSONObject {
    static var mock: JSONObject {
        [
            "key1": "value1",
            "key2": [
                "key2.1": "value2.1"
            ]
        ]
    }
}

final class JSONProcessorTests: XCTestCase {

    private var sut: JSONProcessor!

    override func setUp() {
        super.setUp()
        sut = JSONProcessor()
    }

    func test_encodeRequestFeatures_SHOULD_constructRequestJSONWithImpressionId() async throws {
        let jsonData = try sut.encodeRequestFeatures(
            sessionArgsJson: .mock,
            impressionId: "input_impression_id",
            featureKeys: [
                FeatureKey(name: "feature1", argsJson: .mock),
                FeatureKey(name: "feature2", argsJson: .mock)
            ]
        )

        let expectedJSON = """
        {
          "version" : 2,
          "args" : {
            "key1" : "value1",
            "key2" : {
              "key2.1" : "value2.1"
            }
          },
          "impressionId" : "input_impression_id",
          "reqs" : [
            {
              "name" : "feature1",
              "args" : {
                "key1" : "value1",
                "key2" : {
                  "key2.1" : "value2.1"
                }
              }
            },
            {
              "name" : "feature2",
              "args" : {
                "key1" : "value1",
                "key2" : {
                  "key2.1" : "value2.1"
                }
              }
            }
          ]
        }
        """

        XCTAssertEqual(jsonData.jsonString(), expectedJSON)
    }

    func test_encodeRequestFeatures_SHOULD_constructRequestJSONWithoutImpressionId() async throws {
        let jsonData = try sut.encodeRequestFeatures(
            sessionArgsJson: .mock,
            impressionId: nil,
            featureKeys: [
                FeatureKey(name: "feature1", argsJson: .mock),
                FeatureKey(name: "feature2", argsJson: .mock)
            ]
        )

        let expectedJSON = """
        {
          "version" : 2,
          "args" : {
            "key1" : "value1",
            "key2" : {
              "key2.1" : "value2.1"
            }
          },
          "reqs" : [
            {
              "name" : "feature1",
              "args" : {
                "key1" : "value1",
                "key2" : {
                  "key2.1" : "value2.1"
                }
              }
            },
            {
              "name" : "feature2",
              "args" : {
                "key1" : "value1",
                "key2" : {
                  "key2.1" : "value2.1"
                }
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

        let jsonData = try sut.encodeSignalEvent(
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

    func test_encodeSignalCachedFeatures_SHOULD_generateWithOnAndOffFeatures() async throws {
        let session = Session(deviceId: fakeDeviceId, required: 0)

        let outputs = MockFeatureA.Outputs(_impressionId: "old-impression-id", out1: "out", out2: 3)
        let jsonData = try sut.encodeSignalCachedFeatures(
            cachedItems: [
                FeatureCacheItem(
                    key: FeatureKey(name: "OnFeature", argsJson: [:]),
                    status: .on(
                        outputsJson: outputs.encodeToJSONObject()
                    )
                ),
                FeatureCacheItem(
                    key: FeatureKey(name: "OffFeature", argsJson: [:]),
                    status: .off
                )
            ],
            session: session,
            impressionId: fakeImpressionId
        )

        let expectedJSON = """
        {
          "id" : {
            "deviceId" : "\(fakeDeviceId)"
          },
          "impressions" : {
            "OffFeature" : {
              "newImpression" : "\(fakeImpressionId)"
            },
            "OnFeature" : {
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

        let jsonData = try sut.encodeKeepAlive(session: session)

        let expectedJSON = """
        {
          "deviceId" : "\(fakeDeviceId)"
        }
        """

        XCTAssertEqual(jsonData.jsonString(), expectedJSON)
    }

    func test_decodeData() async throws {
        let validData = String("{ \"status\" : \"ok\" }").data(using: .utf8)!
        let json = try sut.decode(data: validData)
        XCTAssertEqual(json, ["status": "ok"])

        let corruptData = Data()
        XCTAssertThrowsError(try sut.decode(data: corruptData))
    }

    func test_decodeRequestFeatures_SHOULD_throwErrorWhenMissingSession() throws {
        let json = """
        {
          "impressions": [
             {
               "_impressionId" : "\(fakeImpressionId)",
               "callToAction" : "TRY THIS",
               "actionButton": "New Button"
             }
          ]
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        XCTAssertThrowsError(try sut.decodeRequestFeatures(response: data)) { error in
            XCTAssertEqual(error as? CausalError, .parseFailure(message: "Unable to locate `session` in the response."))
        }
    }

    func test_decodeRequestFeatures_SHOULD_throwErrorWhenMissingImpressions() throws {
        let json = """
        {
          "session": {
             "deviceId" : "\(fakeDeviceId)",
             "sessionId" : "89096d5b-fd42-4dd5-bec3-faa31579d388",
             "startTime" : 1684278833067
          }
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        XCTAssertThrowsError(try sut.decodeRequestFeatures(response: data)) { error in
            XCTAssertEqual(error as? CausalError, .parseFailure(message: "Unable to locate `impressions` in the response."))
        }
    }

    func test_decodeRequestFeatures_SHOULD_throwErrorWhenInvalidImpressionDataSupplied() throws {
        let json = """
        {
          "session": {
             "deviceId" : "\(fakeDeviceId)",
             "sessionId" : "89096d5b-fd42-4dd5-bec3-faa31579d388",
             "startTime" : 1684278833067
          },
          "impressions": [
             {
               "_impressionId" : "\(fakeImpressionId)",
               "callToAction" : "TRY THIS",
               "actionButton": "New Button"
             },
             "invalid"
          ]
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        XCTAssertThrowsError(try sut.decodeRequestFeatures(response: data)) { error in
            XCTAssertEqual(error as? CausalError, .parseFailure(message: "Received unknown impression data: invalid"))
        }
    }

    func test_decodeRequestFeatures_SHOULD_returnParsedResponseWithRegisteredDevice() throws {
        let json = """
        {
          "session": {
             "deviceId" : "\(fakeDeviceId)",
             "sessionId" : "89096d5b-fd42-4dd5-bec3-faa31579d388",
             "startTime" : 1684278833067
          },
          "impressions": [
            "OFF",
             {
               "_impressionId" : "\(fakeImpressionId)",
               "callToAction" : "TRY THIS",
               "actionButton": "New Button"
             },
            "OFF"
          ],
          "registered": true
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try sut.decodeRequestFeatures(response: data)
        XCTAssertEqual(
            response,
            RequestFeaturesResponse(
                isDeviceRegistered: true,
                sessionJson: [
                    "deviceId": fakeDeviceId,
                    "sessionId": "89096d5b-fd42-4dd5-bec3-faa31579d388",
                    "startTime": 1_684_278_833_067
                ],
                encodedFeatureStatuses: [
                    .off,
                    .on(
                        outputsJson: [
                            "_impressionId": fakeImpressionId,
                            "callToAction": "TRY THIS",
                            "actionButton": "New Button"
                        ]
                    ),
                    .off
                ]
            )
        )
    }

    func test_decodeRequestFeatures_SHOULD_returnParsedResponseWithoutRegisteredDevice() throws {
        let json = """
        {
          "session": {
             "deviceId" : "\(fakeDeviceId)",
             "sessionId" : "89096d5b-fd42-4dd5-bec3-faa31579d388",
             "startTime" : 1684278833067
          },
          "impressions": [
            "OFF",
             {
               "_impressionId" : "\(fakeImpressionId)",
               "callToAction" : "TRY THIS",
               "actionButton": "New Button"
             },
            "OFF"
          ]
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try sut.decodeRequestFeatures(response: data)
        XCTAssertEqual(
            response,
            RequestFeaturesResponse(
                isDeviceRegistered: false,
                sessionJson: [
                    "deviceId": fakeDeviceId,
                    "sessionId": "89096d5b-fd42-4dd5-bec3-faa31579d388",
                    "startTime": 1_684_278_833_067
                ],
                encodedFeatureStatuses: [
                    .off,
                    .on(
                        outputsJson: [
                            "_impressionId": fakeImpressionId,
                            "callToAction": "TRY THIS",
                            "actionButton": "New Button"
                        ]
                    ),
                    .off
                ]
            )
        )
    }
}
