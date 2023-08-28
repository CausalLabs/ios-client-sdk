//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

/// Describes all the events that the view can send into the view model
public enum FeatureViewModelEvent {
    /// Indicates that the view was shown on the screen
    case onAppear

    /// Indicates that the view is no longer visible
    case onDisappear
}
