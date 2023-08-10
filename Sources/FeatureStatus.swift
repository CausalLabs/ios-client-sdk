//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

/// Describes the current status of a feature.
public enum FeatureStatus<T: FeatureOutputsProtocol>: Equatable {
    /// The feature has yet to be requested.
    case unrequested

    /// The Feature is active and has the following outputs.
    /// - Parameter outputs: The output data for this active feature.
    case on(outputs: T)
    // swiftlint:disable:previous identifier_name

    /// This feature is not currently active.
    case off
}
