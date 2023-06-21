//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// A property wrapper that requires a value to be set once.
@propertyWrapper
public struct RequiredOnce<T> {
    var value: T?

    private let description: String
    private let resettable: Bool

    /// :nodoc:
    public init(description: String, resettable: Bool = false) {
        self.description = description
        self.resettable = resettable
    }

    /// :nodoc:
    public var wrappedValue: T {
        get {
            guard let value = self.value else {
                preconditionFailure("Missing value. Please provide: \(self.description).")
            }
            return value
        }
        set {
            if self.resettable {
                self.value = newValue
            } else {
                guard self.value == nil else {
                    preconditionFailure("Value for \(self.description) can only be set once.")
                }
                self.value = newValue
            }
        }
    }
}
