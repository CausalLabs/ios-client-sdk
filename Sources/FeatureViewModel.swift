//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// Describes a view model for a feature
public protocol FeatureViewModel: AnyObject {

    /// Requests this view model's feature.
    func requestFeature() async
}

/// A view modifier for requesting a feature.
public struct FeatureRequest: ViewModifier {

    /// The feature view model.
    public let viewModel: FeatureViewModel

    @State private var _hasMadeRequest = false

    /// Modifies the inner `content` to fetch the specified feature when the view initially appears.
    public func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content.task {
                guard !self._hasMadeRequest else { return }
                self._hasMadeRequest = true
                await self.viewModel.requestFeature()
            }
        } else {
            content.onAppear {
                guard !self._hasMadeRequest else { return }
                self._hasMadeRequest = true
                Task {
                    await self.viewModel.requestFeature()
                }
            }
        }
    }
}

extension View {
    /// Requests the specified feature exactly once from the Causal API.
    ///
    /// - Parameter viewModel: The view model for the feature.
    /// - Returns: The modified view.
    public func requestFeature(_ viewModel: FeatureViewModel) -> some View {
        self.modifier(FeatureRequest(viewModel: viewModel))
    }
}
