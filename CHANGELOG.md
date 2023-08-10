# Changelog

The changelog for `CausalLabs/ios-client-sdk`. Also see the [releases](https://github.com/CausalLabs/ios-client-sdk/releases) on GitHub.

## 0.10.0

- Improved event signaling contract allowing for a better autocomplete experience.
- Added a public protocol (`CausalClientProtocol`) that `CausalClient` conforms to allowing for mock instances of the client to be used in unit tests.
- Added a public constructor to `CausalClient`.
- Updated how a feature exposes arguments and outputs fetched from the server.
  - Arguments are now available as an `args` variable on the feature object.
  - Outputs are now available as a `status` variable on the feature. The status field is an enum which details the response returned from the impression server. The different status states are as follows:
    - **unrequested**: The feature has been constructed but the client hasn't updated it yet.
    - **on**: The feature was successfully loaded and is active (on). Access to the outputs is available as an associated value.
    - **off**: The feature was successfully loaded and is not active (off).
- Updated the compiler generated view models to expose a `state` object which helps the underlying view render all of the different states that the feature can be in. The different states are as follows:
  - **on**: Indicates that the feature was successfully loaded (either from cache or network) and is active. Access to the feature outputs is available as an associated value.
  - **off**: Indicates that the feature was successfully loaded (either from cache or network) and is not active. These should not be shown.
  - **loading**: Indicates that the feature is currently being loaded.
- Updated the `CausalClient.requestCacheFill` method to no longer mutate input arguments.

## 0.9.0

- Feature caching fixes and improvements.

## 0.8.0

- `CausalClient.requestCacheFill` method has been updated to correctly parse the `\_impressionId` returned by the impression service.
- `CausalClient.updateFeatures` has been removed.
- `CausalClient.requestFeatures` & `CausalClient.requestFeature` methods have been modified to update in-place the passed in `feature(s)` reference object(s) with data from the cache or impression service. With this change these methods are no longer marked as `throws` and will return an optional `Error` if one was encountered during the request.
- `FeatureRequest` has been updated to only request the feature once on iOS 15+

## 0.7.0

- `CausalClient.shared.session` is now optional and no longer asserts with a `preconditionFailure()` when missing. Instead, all throwing APIs that require a session will throw a `missingSession` error if called when the `session` is `nil`. All non-throwing APIs will use default values (return default features) and not send network events.
- `CausalClient.keepAlive()` is no longer marked `async throws`.

## 0.6.0

- Fix session events
- Fix default value generation

## 0.5.0

- Session objects generate a new `persistentId` property that corresponds to the `@persistent_key` annotation in FDL files.
- Implemented [server sent events](https://tech.causallabs.io/docs/reference/iserver-endpoints/#iserversse).
  - Open an SSE connection and begin listening for events using `CausalClient.shared.startSSE()`.
  - Close the connection using `CausalClient.shared.stopSSE()`.

## 0.4.0

- Added the ability to initialize Session objects from a session key.

## 0.3.0

- Fix potential issue generating Swift enum properties.

## 0.2.0

- Fix various code generation issue (e.g. when event was specified with no parameters).
- Documentation improvements and fixes.
- Unit test fixes and improvements.

## 0.1.0

- Initial pre-release.
