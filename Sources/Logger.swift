//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// Describes the verbosity of debug logging.
public enum DebugLogVerbosity {
    /// Disables all logging.
    case off

    /// Enable logging for errors only.
    case errors

    /// Enables all logging. Logs include info messages, warnings, and errors.
    case verbose
}

private enum LogLevel: String {
    case info
    case warning
    case error
}

final class Logger {
    static let shared = Logger()

    var verbosity = DebugLogVerbosity.errors

    func info(_ message: String,
              file: StaticString = #file,
              function: StaticString = #function,
              line: Int = #line) {
        self._log(level: .info, message: message, file: file, function: function, line: line)
    }

    func info(_ message: String,
              jsonData: Data,
              file: StaticString = #file,
              function: StaticString = #function,
              line: Int = #line) {
        self.info("\(message)\nJSON Data:\n\(jsonData.jsonString())", file: file, function: function, line: line)
    }

    func warning(_ message: String,
                 file: StaticString = #file,
                 function: StaticString = #function,
                 line: Int = #line) {
        self._log(level: .warning, message: message, file: file, function: function, line: line)
    }

    func error(_ message: String,
               error: Error,
               file: StaticString = #file,
               function: StaticString = #function,
               line: Int = #line) {
        let messageWithError = """
            \(message)
            Error: \(error.localizedDescription)
            \(error)
            """
        self._log(level: .error, message: messageWithError, file: file, function: function, line: line)
    }

    private func _allowLogs(level: LogLevel) -> Bool {
        switch self.verbosity {
        case .off:
            return false

        case .errors:
            return level == .error

        case .verbose:
            return true
        }
    }

    private func _log(level: LogLevel,
                      message: String,
                      file: StaticString,
                      function: StaticString,
                      line: Int) {
        guard self._allowLogs(level: level) else { return }

        var log = "[CausalLabsSDK] \(level.rawValue.uppercased())"
        log.append("""

        File: \(file)
        Location: \(function) - Line: \(line)
        """)

        print("""
        \(log)
        Message: \(message)

        """)
    }
}
