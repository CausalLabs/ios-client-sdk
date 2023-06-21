//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

/// Describes a unique session identifier.
public typealias SessionId = String

/// Describes a unique device identifier.
public typealias DeviceId = String

/// Describes a unique impression identifier.
public typealias ImpressionId = String

/// Describes a unique feature identifier.
public typealias FeatureId = String

extension String {
    /// Returns a new, unique identifier.
    public static func newId() -> Self {
        UUID().uuidString
    }
}
