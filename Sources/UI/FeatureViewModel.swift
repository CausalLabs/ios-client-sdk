//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

/// Describes a view model for a feature
public protocol FeatureViewModel: AnyObject {
    /// Trigger a view event into the view model
    func onEvent(_ event: FeatureViewModelEvent)
}
