//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

/// Describes an object which can return a list of products
protocol FetchProductsUseCaseProtocol {

    /// Fetch a list of products
    /// - Parameter searchQuery: search query used to refine the products returned
    /// - Returns: list of filtered products
    func execute(searchQuery: String) async throws -> [Product]
}
