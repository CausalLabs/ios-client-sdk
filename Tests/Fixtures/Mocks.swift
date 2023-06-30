//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import Foundation

let fakeJSON = "{ \"status\" : \"ok\" }"

private let defaultResponse = String(fakeJSON)

final class MockNetworkingClient: Networking {
    var configuration = URLSessionConfiguration.default

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

    var receivedBodyString: String {
        self.receivedBody?.jsonString() ?? ""
    }

    var receivedBodyJSON: JSONObject {
        guard let data = self.receivedBody else {
            return [:]
        }
        let jsonObject = try? JSONSerialization.jsonObject(with: data) as? JSONObject
        return jsonObject ?? [:]
    }

    @discardableResult
    func sendRequest(
        baseURL: URL,
        endpoint: CausalEndpoint,
        session: any SessionProtocol,
        body: Data
    ) async throws -> Data {
        Logger.shared.info("MOCK: sending request to \(endpoint)...")

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
        self.configuration = .default
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

final class MockFeature: FeatureProtocol, Equatable {
    static let name = "mock feature"

    var id: String { Self.name }

    var isActive = true

    var impressionIds = [ImpressionId]()

    func args() throws -> JSONObject {
        JSONObject()
    }

    func updateFrom(json: JSONObject) { }

    func copy(newImpressionId: ImpressionId) -> MockFeature {
        let copy = MockFeature()
        copy.isActive = self.isActive
        copy.impressionIds = [newImpressionId]
        return copy
    }

    static func == (left: MockFeature, right: MockFeature) -> Bool {
        left.id == right.id
        && left.isActive == right.isActive
        && left.impressionIds == right.impressionIds
    }
}

struct MockEvent: EventProtocol {
    static let featureName = "feature"

    static let name = "event"

    func serialized() -> JSONObject {
        JSONObject()
    }
}

final class MockFeatureViewModel: FeatureViewModel {
    var stubbedRequestFeature: () -> Void = { }

    func requestFeature() async throws {
        self.stubbedRequestFeature()
    }
}
