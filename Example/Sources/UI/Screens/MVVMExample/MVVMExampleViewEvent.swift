//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

/// Describes this view layer events that the view model can react to.
enum MVVMExampleViewEvent {
    /// A new search query was entered into the search input
    case onSearchChanged(query: String)

    /// The retry button was selected
    case onRetryButtonTap

    /// The view came into view.
    case onAppear
}
