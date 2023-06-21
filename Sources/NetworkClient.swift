//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

protocol Networking {
    /// Sends a request to the impression server with the given parameters.
    @discardableResult
    func sendRequest(baseURL: URL,
                     endpoint: CausalEndpoint,
                     session: any SessionProtocol,
                     body: Data) async throws -> Data
}

final class NetworkClient: Networking {
    private let urlSession: URLSession

    private let logger: Logger

    init(urlSession: URLSession = .shared, logger: Logger = .shared) {
        self.urlSession = urlSession
        self.logger = logger
    }

    // MARK: Networking

    @discardableResult
    func sendRequest(baseURL: URL,
                     endpoint: CausalEndpoint,
                     session: any SessionProtocol,
                     body: Data) async throws -> Data {
        self.logger.info(jsonData: body)

        let request = try URLRequest(impressionServer: baseURL,
                                     endpoint: endpoint,
                                     session: session,
                                     body: body)

        var receivedResponse: HTTPURLResponse?
        var receivedData: Data?
        do {
            let (data, response) = try await self.urlSession.data(for: request)
            receivedData = data
            receivedResponse = response.httpResponse

            self.logger.info("Response: \(response)")

            if let receivedResponse, receivedResponse.isError {
                throw CausalError.networkResponse(request: request,
                                                  response: receivedResponse,
                                                  error: nil)
            }

            return data
        } catch {
            // URLSession can throw an error, even if the request succeeded.
            // This usually describes an application error, not necessarily a networking error.
            // For example, `data` could be `nil`.
            // If the request returned an error response (400, 500, etc.), then re-throw the error.
            if let receivedResponse, receivedResponse.isError, receivedData != nil {
                self.logger.error(error)
                throw CausalError.networkResponse(request: request,
                                                  response: receivedResponse,
                                                  error: error)
            } else {
                // Otherwise, this is a recoverable application error that we can log and ignore.
                self.logger.error(error, message: "URLSession error")
                return Data()
            }
        }
    }
}
