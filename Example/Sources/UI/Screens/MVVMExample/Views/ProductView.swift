//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import SwiftUI

/// Product Cell View
struct ProductView: View {
    @ObservedObject private var ratingBoxViewModel: RatingBoxViewModel
    @State private var rating: Int = 0
    private let product: MVVMExampleViewState.Product

    /// Constructs the Product Cell
    /// - Parameter product: Product view state object
    init(product: MVVMExampleViewState.Product) {
        self.product = product
        self.ratingBoxViewModel = product.ratingBoxViewModel
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text(product.name)
                        .font(.headline)

                    Spacer()
                    Text(String(format: "$%.02f", product.price))
                }

                Divider()

                Text(product.description)
                    .font(.caption)
            }

            ratingView
                .requestFeature(ratingBoxViewModel)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder private var ratingView: some View {
        switch ratingBoxViewModel.state {
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
            rating: $rating,
            title: outputs.callToAction,
            buttonTitle: outputs.actionButton,
            buttonAction: {
                ratingBoxViewModel.signal(event: .rating(stars: rating))
            }
        )
    }
}
