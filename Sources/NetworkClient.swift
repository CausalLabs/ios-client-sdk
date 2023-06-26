//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

protocol Networking: AnyObject {
    var configuration: URLSessionConfiguration { get set }

    /// Sends a request to the impression server with the given parameters.
    @discardableResult
    func sendRequest(baseURL: URL,
                     endpoint: CausalEndpoint,
                     session: any SessionProtocol,
                     body: Data) async throws -> Data
}

final class NetworkClient: Networking {
    private var urlSession: URLSession

    private let logger: Logger

    init(urlSession: URLSession = .shared, logger: Logger = .shared) {
        self.urlSession = urlSession
        self.logger = logger
    }

    // MARK: Networking

    var configuration: URLSessionConfiguration {
        get {
            self.urlSession.configuration
        }
        set {
            self.urlSession = URLSession(configuration: newValue)
        }
    }

    @discardableResult
    func sendRequest(baseURL: URL,
                     endpoint: CausalEndpoint,
                     session: any SessionProtocol,
                     body: Data) async throws -> Data {
        let request = try URLRequest(impressionServer: baseURL,
                                     endpoint: endpoint,
                                     session: session,
                                     body: body)
        self.logger.info("Sending request: \(request)", jsonData: body)

        var receivedResponse: HTTPURLResponse?
        var receivedData: Data?
        do {
            let (data, response) = try await self.urlSession.data(for: request)
            receivedData = data
            receivedResponse = response.httpResponse

            self.logger.info("""
                Received response for request: \(request)
                Response: \(response)
                """,
                jsonData: data
            )

            if let receivedResponse, receivedResponse.isError {
                let error = CausalError.networkResponse(request: request,
                                                        response: receivedResponse,
                                                        error: nil)
                self.logger.error("Network Request Error", error: error)
                throw error
            }
            return data
        } catch {
            // URLSession can throw an error, even if the request succeeded.
            // This usually describes an application error, not necessarily a networking error.
            // For example, `data` could be `nil`.
            // If the request returned an error response (400, 500, etc.), then re-throw the error.
            if let receivedResponse, receivedResponse.isError, receivedData != nil {
                let error = CausalError.networkResponse(request: request,
                                                        response: receivedResponse,
                                                        error: error)
                self.logger.error("Network Request Error", error: error)
                throw error
            } else {
                // Otherwise, this is a recoverable application error that we can log and ignore.
                self.logger.error("URLSession error", error: error)
                return Data()
            }
        }
    }
}
