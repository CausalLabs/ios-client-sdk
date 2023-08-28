//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import CausalLabsSDK
import Foundation
import SwiftUI

/// Generated ViewModel Example View
///
/// This example shows a sample Causal integration onto a screen using SwiftUI.
struct SwiftUIExampleView: View {
    private let causalClient = CausalClient.shared
    @StateObject private var viewModel = RatingBoxViewModel(product: "SwiftUIExampleView")
    @State private var stars: Int = 0

    var body: some View {
        VStack {
            contentView
                .requestFeature(viewModel)
        }
        .commonToolbar()
        .padding()
    }

    @ViewBuilder private var contentView: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()

        case .off:
            EmptyView()

        case let .on(outputs):
            onView(outputs: outputs)
        }
    }

    private func onView(outputs: RatingBox.Outputs) -> some View {
        // swiftlint:disable:next trailing_closure
        RatingView(
            rating: $stars,
            title: outputs.callToAction,
            buttonTitle: outputs.actionButton,
            buttonAction: {
                viewModel.signal(event: .rating(stars: stars))
            }
        )
    }
}
