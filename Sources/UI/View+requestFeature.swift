//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import SwiftUI

extension View {
    /// Requests the specified feature exactly once from the Causal API.
    ///
    /// - Parameter viewModel: The view model for the feature.
    /// - Returns: The modified view.
    public func requestFeature(_ viewModel: FeatureViewModel) -> some View {
        modifier(FeatureRequest(viewModel: viewModel))
    }
}

/// A view modifier for requesting a feature.
struct FeatureRequest: ViewModifier {

    /// The feature view model.
    let viewModel: FeatureViewModel

    /// Modifies the inner `content` to fetch the specified feature when the view initially appears.
    func body(content: Content) -> some View {
        content
            .onAppear {
                viewModel.onEvent(.onAppear)
            }
            .onDisappear {
                viewModel.onEvent(.onDisappear)
            }
    }
}
