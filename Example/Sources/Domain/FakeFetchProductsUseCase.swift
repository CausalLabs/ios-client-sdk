//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

import Foundation

final class FakeFetchProductsUseCase: FetchProductsUseCaseProtocol {
    private let loremIpsum = [
        "voluptatum",
        "commodi",
        "Aut",
        "dolore",
        "reiciendis",
        "voluptatem",
        "odit",
        "error",
        "Sed",
        "inventore",
        "quo",
        "aspernatur",
        "quod",
        "architecto",
        "et",
        "quos",
        "repellendus",
        "excepturi",
        "pariatur",
        "est",
        "praesentium",
        "optio",
        "accusantium",
        "eveniet",
        "Et",
        "ab",
        "laudantium",
        "ipsa",
        "nihil",
        "dolor",
        "laborum",
        "consectetur",
        "voluptas",
        "Est",
        "magni",
        "ipsum",
        "fugiat",
        "molestias",
        "sed",
        "quam",
        "totam",
        "aut",
        "internos",
        "amet",
        "quibusdam",
        "eligendi",
        "quae.",
        "qui",
        "repudiandae",
        "deserunt",
        "non",
        "beatae",
        "ut",
        "consequatur",
        "Sit",
        "soluta",
        "illum",
        "accusamus",
        "reprehenderit",
        "expedita",
        "neque",
        "sit",
        "consequuntur",
        "debitis",
        "laboriosam",
        "iste",
        "cumque",
        "quasi",
        "Lorem",
        "id",
        "Qui",
        "dolorem"
    ]

    /// Generates a random list of products
    /// - Returns: A random list of products
    func execute(searchQuery: String) async throws -> [Product] {
        // Simulate a network response
        sleep(1)

        // Generate a random list of products
        return (0 ..< Int.random(in: 0 ... 50)).map { _ in
            let name = loremIpsum
                .shuffled()
                .prefix(Int.random(in: 2 ... 4))
                .joined(separator: " ")

            let description = loremIpsum
                .shuffled()
                .prefix(Int.random(in: 10 ... 20))
                .joined(separator: " ")

            return Product(
                id: UUID().uuidString,
                name: name,
                description: description,
                price: Float.random(in: 10.99 ... 199.99)
            )
        }
    }
}
