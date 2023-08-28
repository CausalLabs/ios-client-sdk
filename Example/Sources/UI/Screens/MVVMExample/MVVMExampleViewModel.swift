//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import CausalLabsSDK
import SwiftUI

@MainActor
final class MVVMExampleViewModel: ObservableObject {
    /// Causal Client used to populate the feature cache for quick renders
    private let causalClient: CausalClientProtocol

    /// Used to fetch products to render on the screen
    private let fetchProductsUseCase: FetchProductsUseCaseProtocol

    /// Store current fetch task so that we can cancel the current
    /// task if a new one is initiated.
    private var fetchTask: Task<Void, Never>?

    /// Is this the first time that the corresponding view has appeared?
    private var isFirstAppear = true

    /// Object containing internal data necessary to create the view state.
    /// On change this will generate and set the new view state.
    private var viewModelState: ViewModelState {
        didSet {
            let newViewState = viewModelState.viewState
            guard newViewState != viewState else { return }
            viewState = newViewState
        }
    }

    /// Object containing all information the view needs to render.
    @Published private(set) var viewState = MVVMExampleViewState(searchQuery: "", content: .loading)

    /// Factory closure that can build RatingBoxViewModels.
    private let ratingViewModelFactory: (_ productName: String) -> RatingBoxViewModel

    /// Constructs an instance of the view model
    /// - Parameters:
    ///   - causalClient: Instance of the causal client to use when populating the feature cache
    ///   - fetchProductsUseCase: Object which can fetch a list of products
    ///   - ratingViewModelFactory: Factory closure that can build RatingBoxViewModels.
    init(
        causalClient: CausalClientProtocol,
        fetchProductsUseCase: FetchProductsUseCaseProtocol = FakeFetchProductsUseCase(),
        ratingViewModelFactory: @escaping (_ productName: String) -> RatingBoxViewModel
    ) {
        self.causalClient = causalClient
        self.fetchProductsUseCase = fetchProductsUseCase
        self.ratingViewModelFactory = ratingViewModelFactory

        self.viewModelState = ViewModelState(
            searchQuery: "",
            result: .loading
        )
    }

    /// Handle events from the view layer
    /// - Parameter event: the view event to handle
    func onEvent(_ event: MVVMExampleViewEvent) {
        switch event {
        case .onAppear:
            onAppear()

        case let .onSearchChanged(query):
            onSearchChanged(query: query)

        case .onRetryButtonTap:
            onRetryButtonTap()
        }
    }

    private func onAppear() {
        guard isFirstAppear else { return }
        isFirstAppear = false
        fetchProducts()
    }

    private func onSearchChanged(query: String) {
        viewModelState.searchQuery = query
        fetchProducts()
    }

    private func onRetryButtonTap() {
        fetchProducts()
    }

    /// Fetch the feature from the client and update the internal state.
    private func fetchProducts() {
        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            guard let self else { return }

            self.viewModelState.result = .loading
            do {
                // Fetch the products from the backend
                let products = try await self.fetchProductsUseCase.execute(searchQuery: self.viewModelState.searchQuery)

                guard !Task.isCancelled else { return }

                var features: [RatingBox] = []
                var results: [(product: Product, ratingBoxViewModel: RatingBoxViewModel)] = []
                for product in products {
                    features.append(RatingBox(product: product.name))
                    results.append((product: product, ratingBoxViewModel: self.ratingViewModelFactory(product.name)))
                }

                // Populate the Causal feature cache for a fast initial render.
                try? await self.causalClient.requestCacheFill(features: features)
                self.viewModelState.result = .success(results)
            } catch {
                self.viewModelState.result = .failure(error)
            }
        }
    }
}

/// Describes all internal mutable state which can be used to derive the view state.
private struct ViewModelState {
    /// The current search query
    var searchQuery: String

    /// The result of fetching the list of products (loading | failure | success)
    var result: AsyncResult<[(product: Product, ratingBoxViewModel: RatingBoxViewModel)]>
}

private extension ViewModelState {
    /// Generate the viewState from the current values in the ViewModelState
    var viewState: MVVMExampleViewState {
        MVVMExampleViewState(
            searchQuery: searchQuery,
            content: content
        )
    }

    /// Generate the `content` portion of the view state from the current values in the ViewModelState
    private var content: MVVMExampleViewState.Content {
        switch result {
        case .loading:
            return .loading

        case .failure:
            return .error

        case let .success(result):
            let products = result.map { product, ratingBoxViewModel in
                MVVMExampleViewState.Product(
                    id: product.id,
                    name: product.name,
                    description: product.description,
                    price: product.price,
                    ratingBoxViewModel: ratingBoxViewModel
                )
            }

            return .loaded(MVVMExampleViewState.LoadedState(products: products))
        }
    }
}
