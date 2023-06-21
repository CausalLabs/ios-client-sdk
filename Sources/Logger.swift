//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

private enum LogLevel: String {
    case info
    case warning
    case error
}

final class Logger {
    static let shared = Logger()

    var enabled = false

    var includeFileLocation = false

    private init() {
    #if DEBUG
        self.enabled = true
    #else
        self.enabled = false
    #endif
    }

    func info(_ message: String,
              file: StaticString = #file,
              function: StaticString = #function,
              line: Int = #line) {
        self._log(level: .info, message: message, file: file, function: function, line: line)
    }

    func info(jsonData: Data,
              file: StaticString = #file,
              function: StaticString = #function,
              line: Int = #line) {
        self.info("JSON Data:\n\(jsonData.jsonString())\n", file: file, function: function, line: line)
    }

    func warning(_ message: String,
                 file: StaticString = #file,
                 function: StaticString = #function,
                 line: Int = #line) {
        self._log(level: .warning, message: message, file: file, function: function, line: line)
    }

    func error(_ error: Error,
               message: String? = nil,
               file: StaticString = #file,
               function: StaticString = #function,
               line: Int = #line) {
        let messageWithError = """
            \(message ?? "none")
            Error: \(error.localizedDescription)
            \(error)
            """
        self._log(level: .error, message: messageWithError, file: file, function: function, line: line)
    }

    private func _log(level: LogLevel,
                      message: String,
                      file: StaticString,
                      function: StaticString,
                      line: Int) {
        guard self.enabled else { return }

        var log = "[CausalLabsSDK] \(level.rawValue.uppercased())"

        if self.includeFileLocation {
            log.append("""

            File: \(file)
            Location: \(function) - Line: \(line)
            """)
        }

        print("""
        \(log)
        Message: \(message)
        """)
    }
}
