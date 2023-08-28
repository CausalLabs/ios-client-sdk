//
// Copyright © 2023-present Causal Labs, Inc. All rights reserved.
//

/// Describes the result of fetching an async resource
enum AsyncResult<T> {
    /// The request is currently ongoing.
    case loading

    /// The request failed
    case failure(Error)

    /// The request was successful
    case success(T)
}
