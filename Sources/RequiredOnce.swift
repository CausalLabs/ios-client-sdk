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

    /// Constructs the `RequiredOnce` property wrapper
    /// - Parameters:
    ///   - description: A message to be displayed if the property is accessed/modified incorrectly
    ///   - resettable: whether or not the property can be modified after the initial setting.
    public init(description: String, resettable: Bool = false) {
        self.description = description
        self.resettable = resettable
    }

    /// The `RequiredOnce` wrapped value
    /// - Note: This will throw a `preconditionFailure` when accessing the property before
    ///     it is set and when attempting to set an already set property when the `resettable`
    ///     flag is set to `false`.
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
