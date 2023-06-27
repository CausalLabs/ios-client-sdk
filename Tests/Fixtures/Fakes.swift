//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import Foundation

let fakeImpressionServer = URL(string: "https://tools.causallabs.io/sandbox-iserver")!

let fakeImpressionId = String.newId()

let fakeDeviceId = String.newId()

struct FakeSession: SessionProtocol {

    var deviceId = fakeDeviceId

    var id: SessionId {
        "Session"
    }

    func args() -> JSONObject {
        ["deviceId": deviceId]
    }

    func keys() -> CausalLabsSDK.JSONObject {
        args()
    }

    func updateFrom(json: JSONObject) { }
}

extension CausalClient {
    static func fake(
        featureCache: FeatureCache,
        mockNetworkingClient: MockNetworkingClient = MockNetworkingClient(),
        sessionTimer: SessionTimer = SessionTimer(),
        session: any SessionProtocol = FakeSession(),
        impressionServer: URL = fakeImpressionServer) -> CausalClient {
        let client = CausalClient(networkClient: mockNetworkingClient,
                                  featureCache: featureCache,
                                  sessionTimer: sessionTimer)
        client.impressionServer = impressionServer
        client.session = session
        client.debugLogging = .verbose
        return client
    }
}

extension HTTPURLResponse {
    static func fake(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: fakeImpressionServer,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}

extension CausalError {
    static func fakeNetwork() -> CausalError {
        CausalError.networkResponse(
            request: URLRequest(url: URL(string: "http://causallabs.io")!),
            response: HTTPURLResponse(),
            error: nil
        )
    }
}

enum FakeError: Error {
    case missingInfo
}
