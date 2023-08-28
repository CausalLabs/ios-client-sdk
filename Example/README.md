# Causal Example App

## Integration Examples

This app showcases two Causal Client integration examples.

### Simple SwiftUI intergation

The first example showcases a simple integration adding a feature to a SwiftUI view. The source can be found [here](Sources/UI/Screens/SwiftUIExample/SwiftUIExampleView.swift).

This example shows a sample Causal RatingBox feature that is displayed on the screen.

> **Note**
>
> When running the example app this screen will be visible on the `Basic SwiftUI Example` tab.

### More Complex Example

The second example showcases a more complex integration adding multiple features to a screen which is built using the MVVM design pattern. The source for this example can be found [here](Sources/UI/Screens/MVVMExample/).

This example shows a sample product list screen with search functionality. Each product that is displayed in the result list will have a Causal RatingBox feature embedded within it. The view model is making use of the `CausalClient.requestCacheFill` method to pre-populate the feature cache so when the screen is rendered the RatingBox features will load very quickly from the cache.

> **Note**
>
> When running the example app this screen will be visible on the `MVVM Example` tab.

## Running the Example app

1. Open the [example app project](ExampleApp.xcodeproj) in xcode.
2. Ensure that the scheme is set to `ExampleApp`
3. Run the project by either using the `CMD R` keyboard shortcut or by selecting `Run` under the `Product` menu.
