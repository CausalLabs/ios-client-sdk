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

> TODO: explain adding build script phase

## Documentation

- [iOS SDK documentation](https://causallabs.github.io/ios-client-sdk)

- [Causal reference documentation](https://tech.causallabs.io/docs/index)

## License

See `LICENSE.txt` for details.

> **Copyright © 2023-present Causal Labs, Inc. All rights reserved.**
