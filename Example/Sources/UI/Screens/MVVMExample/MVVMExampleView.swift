//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import CausalLabsSDK
import SwiftUI

/// MVVM Example View
///
/// This example shows a sample Causal integration onto a screen which uses the MVVM architecture.
struct MVVMExampleView: View {
    // swiftlint:disable:next trailing_closure
    @StateObject private var viewModel = MVVMExampleViewModel(
        causalClient: CausalClient.shared,
        ratingViewModelFactory: { name in
            RatingBoxViewModel(client: CausalClient.shared, product: name)
        }
    )

    var body: some View {
        contentView
            .searchable(text: Binding(
                get: { viewModel.viewState.searchQuery },
                set: { viewModel.onEvent(.onSearchChanged(query: $0)) }
            ))
            .commonToolbar()
            .onAppear { viewModel.onEvent(.onAppear) }
    }

    @ViewBuilder private var contentView: some View {
        switch viewModel.viewState.content {
        case .loading:
            loadingView

        case .error:
            errorView

        case let .loaded(loadedState):
            loadedView(loadedState: loadedState)
        }
    }

    private var loadingView: some View {
        ProgressView()
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Text("Error Occurred")
                .font(.headline)

            Button("Retry") {
                viewModel.onEvent(.onRetryButtonTap)
            }
            .buttonStyle(.bordered)
            .padding()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 8) {
            Text("No Products Found")
                .font(.headline)

            Text("Please try a different search query")
                .font(.subheadline)
        }
    }

    @ViewBuilder
    private func loadedView(loadedState: MVVMExampleViewState.LoadedState) -> some View {
        if loadedState.products.isEmpty {
            noResultsView
        } else {
            ScrollView {
                LazyVStack {
                    ForEach(loadedState.products) { product in
                        ProductView(product: product)
                    }
                }
                .padding()
            }
        }
    }
}
