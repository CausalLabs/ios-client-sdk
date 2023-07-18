//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// Describes possible errors thrown by the Causal SDK.
public enum CausalError: Error, Equatable, CustomStringConvertible {
    /// Indicates an error occurred when encoding, decoding, or processing json.
    ///
    /// - Parameter json: The json data causing the error.
    /// - Parameter error: The underlying error, if available.
    case json(json: String, error: Error?)

    /// Indicates an error occurred with the server response.
    ///
    /// - Parameter request: The url request.
    /// - Parameter response: The http response.
    /// - Parameter error: The underlying error, if available.
    case networkResponse(request: URLRequest, response: HTTPURLResponse, error: Error?)

    /// Indicates that `CausalClient.shared.session` is unexpectedly `nil`.
    case missingSession

    /// :nodoc:
    public var localizedDescription: String {
        var description = "\(type(of: self)):\n"
        var underlyingError: Error?

        switch self {
        case .json(let json, let error):
            description += """
            - json: \(json)
            """
            underlyingError = error

        case .networkResponse(let request, let response, let error):
            description += """
            - request: \(request)
            - status code: \(response.statusCode)
            - response URL: \(response.url?.absoluteString ?? "nil")
            - response headers: \(response.allHeaderFields)
            """
            underlyingError = error

        case .missingSession:
            description += """
            `CausalClient.shared.session` is unexpectedly `nil`
            """
        }

        if let underlyingError, !(underlyingError is Self) {
            description += """

            - underlying error: \(underlyingError)
            """
        }
        return description
    }

    /// :nodoc:
    public var description: String {
        self.localizedDescription
    }

    // MARK: Equatable

    /// :nodoc:
    public static func == (left: Self, right: Self) -> Bool {
        // note: this is very rudimentary.
        // does not compare enum payloads. intended mostly for testing.
        switch (left, right) {
        case (.json, .json),
             (.networkResponse, .networkResponse),
             (.missingSession, .missingSession):
            return true

        default:
            return false
        }
    }
}
