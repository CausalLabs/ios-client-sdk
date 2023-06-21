//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import Foundation

let fakeJSON = "{ \"status\" : \"ok\" }"

private let defaultResponse = String(fakeJSON)

final class MockNetworkingClient: Networking {
    var stubbedResponse = defaultResponse
    var stubbedError: CausalError?

    var sendRequestCallCount = 0
    var sendRequestWasCalled: Bool {
        self.sendRequestCallCount > 0
    }

    var receivedBaseURL: URL?
    var receivedEndpoint: CausalEndpoint?
    var receivedSession: (any SessionProtocol)?
    var receivedBody: Data?

    @discardableResult
    func sendRequest(
        baseURL: URL,
        endpoint: CausalEndpoint,
        session: any SessionProtocol,
        body: Data
    ) async throws -> Data {
        self.sendRequestCallCount += 1

        self.receivedBaseURL = baseURL
        self.receivedEndpoint = endpoint
        self.receivedSession = session
        self.receivedBody = body

        if let error = self.stubbedError {
            throw error
        }

        return self.stubbedResponse.data(using: .utf8)!
    }

    func reset() {
        self.stubbedResponse = defaultResponse
        self.stubbedError = nil

        self.sendRequestCallCount = 0
        self.receivedBaseURL = nil
        self.receivedEndpoint = nil
        self.receivedSession = nil
        self.receivedBody = nil
    }
}

struct MockSession: SessionProtocol {
    var deviceId = DeviceId.newId()

    var id: SessionId {
        "Session"
    }

    func args() -> JSONObject {
        ["deviceId": deviceId]
    }

    func keys() -> JSONObject {
        ["deviceId": deviceId]
    }

    func updateFrom(json: JSONObject) { }
}

struct MockFeature: FeatureProtocol {
    static let name = "mock feature"

    var id: String { Self.name }

    var isActive = true

    var impressionIds = [ImpressionId]()

    func args() -> JSONObject {
        JSONObject()
    }

    func updateFrom(json: JSONObject) { }
}

struct MockEvent: EventProtocol {
    static let featureName = "feature"

    static let name = "event"

    func serialized() -> JSONObject {
        JSONObject()
    }
}
