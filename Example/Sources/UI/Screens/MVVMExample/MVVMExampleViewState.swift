//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

/// Describes all data required to render the view
struct MVVMExampleViewState: Equatable {
    /// The search query
    let searchQuery: String

    /// The main screen content
    let content: Content
}

extension MVVMExampleViewState {
    /// Describes the different states that the main screen content can be in
    enum Content: Equatable {
        /// The underlying data is being requested
        case loading

        /// There was an unrecoverable error
        case error

        /// The success state
        case loaded(LoadedState)
    }

    /// Describes a product cell that can be rendered to the screen
    struct Product: Equatable, Identifiable {
        /// The id of the product
        let id: String

        /// The name of the product
        let name: String

        /// The description of the product
        let description: String

        /// The price of the product
        let price: Float

        /// Corresponding Causal ViewModel to render the feature
        let ratingBoxViewModel: RatingBoxViewModel

        static func == (lhs: MVVMExampleViewState.Product, rhs: MVVMExampleViewState.Product) -> Bool {
            lhs.id == rhs.id
        }
    }

    /// Describes all data necessary to render the loaded content state.
    struct LoadedState: Equatable {
        /// List of products that should be rendered
        let products: [Product]
    }
}
