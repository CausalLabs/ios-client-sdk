//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

@testable import CausalLabsSDK
import Foundation

let fakeImpressionServer = URL(string: "https://tools.causallabs.io/sandbox-iserver")!

let fakeImpressionId = String.newId()

let fakeDeviceId = String.newId()

extension CausalClient {
    static func fake(
        featureCache: FeatureCache = FeatureCache(),
        mockNetworkingClient: MockNetworkingClient = MockNetworkingClient(),
        sessionTimer: SessionTimer = SessionTimer(),
        session: any SessionProtocol = MockSession(),
        mockSSEClientFactory: MockSSEClientFactory = MockSSEClientFactory(),
        impressionServer: URL = fakeImpressionServer) -> CausalClient {
        let client = CausalClient(networkClient: mockNetworkingClient,
                                  featureCache: featureCache,
                                  sessionTimer: sessionTimer,
                                  sseClientFactory: mockSSEClientFactory)
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
    static func fakeNetwork(statusCode: Int = 500) -> CausalError {
        CausalError.networkResponse(
            request: URLRequest(url: URL(string: "http://causallabs.io")!),
            response: HTTPURLResponse(url: URL(string: "http://causallabs.io")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!,
            error: nil
        )
    }
}

enum FakeError: Error {
    case missingInfo
}
