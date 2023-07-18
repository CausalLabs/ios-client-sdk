//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation
import XCTest

// swiftlint:disable:next identifier_name
public func AsyncAssertThrowsError(
    _ expression: @autoclosure () async throws -> some Any,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        var failureMessage = "AsyncAssertThrowsError failed: did not throw an error"
        let customMessage = message()
        if !customMessage.isEmpty {
            failureMessage.append(" - \(customMessage)")
        }
        XCTFail(failureMessage, file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
