//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

/// Describes a Product entity object
struct Product: Identifiable {
    /// The id of the product
    let id: String

    /// The name of the product
    let name: String

    /// The description of the product
    let description: String

    /// The price of the product
    let price: Float
}
