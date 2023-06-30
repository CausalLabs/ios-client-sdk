# Getting Started

_This guide will help you get started using Causal._

> **Note**
>
> This guide assumes you have completed the [installation and setup instructions](https://github.com/CausalLabs/ios-client-sdk/blob/main/README.md).

### Additional Resources

- [iOS SDK Documentation](https://causallabs.github.io/ios-client-sdk)
- [iOS Example App](https://github.com/CausalLabs/ios-client-sdk/tree/main/Example)
- [iOS SDK Unit Tests](https://github.com/CausalLabs/ios-client-sdk/tree/main/Tests)
- [Causal Reference Documentation](https://tech.causallabs.io/docs/index)
- [Causal Labs](https://causallabs.io)

## Introduction

The SDK is written in a way that provides two layers: the core "raw" API, and a convenience API wrapper.

The core API is provided by `CausalClient`. This allows you to request features and signal events directly.

The convenience API is generated from your FDL file. Some APIs, like signaling events, are available as methods you can call directly on your feature objects. We also generate a view model object for each feature that encapsulates all functionality for a single feature, reducing most of the boilerplate required for interacting with features and events. `CausalClient` also provides some additional convenience methods.

## Write your [FDL file](https://tech.causallabs.io/docs/fdl/example-fdl)

The first step is defining your features and events. Here's a small example:

```
feature RatingBox {
    args {
        "The product that we are collecting ratings for"
        product: String!
    }

    output {
        "The text next to the stars that prompts the visitor to rate the product"
        callToAction: String! = "Rate this product!"

        "The button text for the user submit a review."
        actionButton: String! = "Send Review"
    }

    "Occurs each time a rating is collected"
    event Rating {
        stars: Int!
    }
}
```

Build your Xcode project to generate and view the corresponding Swift code.

## Configure the `CausalClient`

The `CausalClient` is the main entry point into the SDK. Before you start writing code to use the features you defined in your FDL file, you need to configure the `CausalClient`.

This setup should occur during app launch, **before** you attempt to use any part of the SDK, or your generated features and events.

```swift
// Set the URL for your impression server
CausalClient.shared.impressionServer = URL(string: "https://tools.causallabs.io/sandbox-iserver")!

// Construct and set your initial session
CausalClient.shared.session = Session(deviceId: UUID().uuidString)
```

For SwiftUI apps, configuration should happen during initialization of your `App`:

```swift
@main
struct MyApp: App {
    init() {
        CausalClient.shared.impressionServer = URL(string: "https://tools.causallabs.io/sandbox-iserver")!
        CausalClient.shared.session = Session(deviceId: UUID().uuidString)
    }

    var body: some Scene {
        // ...
    }
}
```

For UIKit apps, configuration should happen in your `AppDelegate`:

```swift
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        CausalClient.shared.impressionServer = URL(string: "https://tools.causallabs.io/sandbox-iserver")!
        CausalClient.shared.session = Session(deviceId: UUID().uuidString)
        return true
    }
}
```

> **Note**
>
> If you need to debug issues with the SDK, you can enable verbose logging:
>
> ```swift
> CausalClient.shared.debugLogging = .verbose
> ```

## Requesting Features

Now you are ready to request features from the impression server.

You can use the core API to request a batch of updated features directly.

```swift
let features = [/* array of features */]

// updates features in-place
await CausalClient.shared.updateFeatures(features)

// you can optionally handle potential errors
let error = await CausalClient.shared.updateFeatures(features)
if let error {
    // check and handle error
}
```

If you prefer a more verbose API, use `requestFeatures()`.

```swift
let features = [/* array of features */]

do {
    try await CausalClient.shared.requestFeatures(features: features)
} catch {
    // handle error
}
```

If desired, you can request a batch of features to be cached for later use. Do this when you want to avoid network requests and have features be available immediately later in your app lifecycle. If using `requestCacheFill()`, you should do so as early as possible in your app lifecycle.


```swift
let features = [/* array of features */]

try? await CausalClient.shared.requestCacheFill(features: features)
```

If you are only interacting with a single feature, we recommend using its corresponding `ViewModel` class instead of the core API. See below for details.

## Using Features

You can now start building your UI that corresponds to your features. You can use your features directly, but we recommend using the generated view model because it encapsulates a lot of common boilerplate. A view model class will be generated for each feature you define. In SwiftUI or UIKit, you can construct the view model and use it to build your view and interact with the feature.

```swift
// Create the view model
let viewModel = RatingBoxViewModel(product: "my product")

// Request the feature
try? await viewModel.requestFeature()

// Do something with the feature
let ratingBox = viewModel.feature

// Signal the feature's events
viewModel.signalRating(stars: 5)
```

However, if you want to use features directly, you can:

```swift
let ratingBox = RatingBox(product: "my product")

await CausalClient.shared.updateFeatures([ratingBox])

// do something with ratingBox
```

## Integration with SwiftUI

For SwiftUI, the best approach is to utilize the feature's view model (which is an `ObservableObject`) to drive your UI. We also provide a convenient view modifier for requesting a feature exactly once during the view lifecycle.

```swift
struct MyView: View {
    // Observe changes to viewModel via @StateObject
    @StateObject var viewModel = RatingBoxViewModel(product: "my product")

    @State var stars: Int = 0

    // Create your view using the properties on viewModel.feature
    var body: some View {
        VStack {
            Text(viewModel.feature?.callToAction ?? "")

            StarsRatingView()

            Button {
                // Signal events directly from the viewModel
                viewModel.signalRating(stars: stars)
            } label: {
                Text(viewModel.feature?.actionButton ?? "")
            }
        }
        // Request the feature exactly once with the view modifier
        .requestFeature(viewModel)
    }
}
```

## Signaling Events

We recommend signaling events via your feature's view model:

```swift
let viewModel = RatingBoxViewModel(product: "my product")

// Signal the feature's "rating" event
viewModel.signalRating(stars: 5)
```

However, you can also call the corresponding `signal*()` method directly on your feature, which is a "fire-and-forget" method:

```swift
let ratingBox = RatingBox(product: "my product")

ratingBox.signalRating(stars: 5)
```

If you prefer to `await` the request and check for errors, you can use `signalAndWait()`:

```swift
let ratingBox = RatingBox(product: "my product")

do {
    try await ratingBox.signalAndWaitRating(stars: 5)
} catch {
    // handle error
}
```
