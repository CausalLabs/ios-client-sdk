//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

/// Describes the different ways that a features status can be updated.
/// - Warning: This is intended for `CausalClient` use only.
public enum FeatureUpdateRequest {
    /// Update this Feature to be on (active)
    /// - Parameters:
    ///   - outputJson: The encoded output data for this active feature.
    ///   - impressionId: (Optional) will overwrite the `_impressionId` supplied in
    ///     `outputJson`. This is useful when hydrating a feature from a cached value
    ///     where the cached impression id is no longer needed and the new impression id
    ///     should be set.
    case on(outputJson: JSONObject, impressionId: ImpressionId?)
    // swiftlint:disable:previous identifier_name

    /// Update this feature to be off (inactive)
    case off
}
