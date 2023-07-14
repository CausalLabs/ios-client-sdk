# Changelog

The changelog for `CausalLabs/ios-client-sdk`. Also see the [releases](https://github.com/CausalLabs/ios-client-sdk/releases) on GitHub.

NEXT
-----

- TBA

0.5.0
-----

- Session objects generate a new `persistentId` property that corresponds to the `@persistent_key` annotation in FDL files.
- Implemented [server sent events](https://tech.causallabs.io/docs/reference/iserver-endpoints/#iserversse).
    - Open an SSE connection and begin listening for events using `CausalClient.shared.startSSE()`.
    - Close the connection using `CausalClient.shared.stopSSE()`.

0.4.0
-----

- Added the ability to initialize Session objects from a session key.

0.3.0
-----

- Fix potential issue generating Swift enum properties.

0.2.0
-----

- Fix various code generation issue (e.g. when event was specified with no parameters).
- Documentation improvements and fixes.
- Unit test fixes and improvements.

0.1.0
-----

Initial pre-release.
