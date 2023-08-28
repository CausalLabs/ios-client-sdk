//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation
import LDSwiftEventSource

enum SSEMessage: Equatable {
    case flushCache(timestamp: TimeInterval)

    case flushFeatures(names: Set<String>)

    case hello(timestamp: TimeInterval)

    init?(eventType: String, messageEvent: MessageEvent) {
        guard let rawEventType = RawEventType(rawValue: eventType) else {
            return nil
        }

        switch rawEventType {
        case .flushCache:
            let timestamp = TimeInterval(messageEvent.data) ?? 0
            self = .flushCache(timestamp: timestamp)

        case .flushFeatures:
            let names = Set(messageEvent.data.split(separator: " ").map { String($0) })
            self = .flushFeatures(names: names)

        case .hello:
            let timestamp = TimeInterval(messageEvent.data) ?? 0
            self = .hello(timestamp: timestamp)
        }
    }
}

/// - Note: all event names are lowercase
private enum RawEventType: String, Equatable {
    /// Flush the entire cache. Save the SSE event data into "lastFlush".
    case flushCache = "flushcache"

    /// Flush the features specified in the SSE event data.
    /// This is a **space delimited** string of feature names.
    case flushFeatures = "flushfeatures"

    /// Get the SSE event data.
    /// If it is greater than any saved "lastFlush",
    /// or no "lastFlash" then flush the cache.
    /// Save the SSE event data to "lastFlush"
    case hello = "hello"
}
