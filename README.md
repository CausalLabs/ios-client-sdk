# Causal Labs iOS SDK

The [Causal Labs](https://www.causallabs.io) iOS SDK integrates Causal with native iOS apps.

## Requirements

- iOS 13.0+
- Swift 5.8+
- Xcode 14.0+

## Package Installation

### [CocoaPods](http://cocoapods.org)

````ruby
pod 'CausalLabsSDK', '~> 0.1.0'
````

### [Swift Package Manager](https://swift.org/package-manager/)

```swift
dependencies: [
    .package(url: "https://github.com/CausalLabs/ios-client-sdk.git", from: "0.1.0")
]
```

Alternatively, you can add the package [directly via Xcode](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).

## Causal Compiler Configuration

1. Install Java 11 (via homebrew)

```bash
brew install java11
```

2. Update your `.zprofile` or `.zshrc` (or equivalent)

```bash
export PATH="/usr/local/opt/openjdk@11/bin:$PATH"
export CPPFLAGS="-I/usr/local/opt/openjdk@11/include $CPPFLAGS"
```

> **Note**
>
> Homebrew should indicate the path to `java` when installation completes.
>
> Depending on your machine configuration, `java` may be located somewhere else.
> If so, you need to replace the path `/usr/local/opt/openjdk@11/libexec/openjdk.jdk` to correspond to your Java installation location.

3. Verify `java` is successfully installed and in your `PATH`

```bash
$ which java
/usr/local/opt/openjdk@11/bin/java
```

```bash
$ java -version
openjdk version "11.0.18" 2023-01-17
OpenJDK Runtime Environment Homebrew (build 11.0.18+0)
OpenJDK 64-Bit Server VM Homebrew (build 11.0.18+0, mixed mode)
```

4. Symlink the JDK so that `causalc` (and `/usr/libexec/java_home`) can find it

```bash
sudo ln -s /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
```

## Xcode Project Configuration

After integrating the SDK (via CocoaPods or SwiftPM) and installing Java, you'll need to add a build script phase to your Xcode project.

1. Navigate to your main application target's `Build Phases` tab.
1. Add a new `Run Script Phase` **before** the `Compile Sources` phase.
1. Name the script phase `FDL Generation`.
1. Set the shell to `/bin/sh`.
1. Create your `Features.fdl` file and place it in your project directory.
1. Add a new file to your project called `Causal.generated.swift`.
1. Add the following script to invoke the compiler and generate your Swift code from your FDL.
    ```bash
    ${PROJECT_DIR}/PATH/TO/CausalLabsSDK/compiler/bin/compiler --swift \
        ${PROJECT_DIR}/PATH/TO/Causal.generated.swift \
        ${PROJECT_DIR}/PATH/TO/Features.fdl
    ```

> **Note**
>
> Replace the paths above with the paths to your files.
>
> For CocoaPods, the path should be: `${PROJECT_DIR}/Pods/CausalLabsSDK/compiler/bin/compiler`
>
> For SwiftPM: TODO
>
> Also, ensure `Causal.generated.swift` has been added to your Xcode project.

**Now you can build and run!** If your build succeeds, you should see your generated code in `Features.generated.swift`. If your build fails, check the build logs and ensure your paths to the compiler and source files are correct.

## Documentation

- [iOS SDK documentation](https://causallabs.github.io/ios-client-sdk)

- [Causal reference documentation](https://tech.causallabs.io/docs/index)

## License

See `LICENSE.txt` for details.

> **Copyright © 2023-present Causal Labs, Inc. All rights reserved.**
