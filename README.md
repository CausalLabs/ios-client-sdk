# iOS SDK

- [iOS SDK Proposal](https://docs.google.com/document/d/1N2HHAPCkbt7b92FJebdLGIe-TFTDP_NI4DJp9TJiQ7I/)

## Environment setup

This describes the minimal setup necessary for building and running the compiler in order to work on the iOS SDK.

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
> Depending on your machine configuration, `java` may be located somewhere else. Determine this by running `which java`.
>
> You may need to replace the path `/usr/local/opt/openjdk@11/libexec/openjdk.jdk` if your Java installation location varies.

```bash
$ which java
/usr/local/opt/openjdk@11/bin/java
```

3. Verify `java` is successfully installed and in your `PATH`

```bash
$ java -version                                                                                                                            X
openjdk version "11.0.18" 2023-01-17
OpenJDK Runtime Environment Homebrew (build 11.0.18+0)
OpenJDK 64-Bit Server VM Homebrew (build 11.0.18+0, mixed mode)
```

4. Symlink the JDK so that `causalc` (and `/usr/libexec/java_home`) can find it

```bash
sudo ln -s /usr/local/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
```

5. Install other utilities

**Install [SwiftLint](https://github.com/realm/SwiftLint/releases/latest)**

```bash
brew install swiftlint
```

**Install [xcpretty](https://github.com/xcpretty/xcpretty)**

```bash
gem install xcpretty
```

**Install [jazzy](https://github.com/realm/jazzy)**

```bash
gem install jazzy
```

## Development Workflow

1. Modify the `.mustache` templates for iOS, found in [`parser/src/main/resources/`](https://github.com/CausalLabs/causal/tree/main/parser/src/main/resources).

```bash
make template
```

2. Build the compiler.

```bash
make build-compiler
```

3. Invoke the compiler, passing in a `.fdl` file and `.swift` file:

```bash
$ ./compiler/build/install/compiler/bin/compiler --swift file.swift file.fdl
```

This will produce generated code in `file.swift` based on the provided `file.fdl`.

## Client Setup

Steps for clients to try it out upon receiving the zip file.

### Prerequisites

1. [Xcode](https://developer.apple.com/xcode/resources/) (14.0 or above)
1. [Bundler](https://bundler.io)
1. [Homebrew](https://brew.sh)
1. [rbenv](https://github.com/rbenv/rbenv)

### Prerequisite directions

#### Install [homebrew](https://docs.brew.sh/Installation)

Don't forget to run "Next Steps" at end of homebrew output:

```console
echo '# Set PATH, MANPATH, etc., for Homebrew.' >> ~/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

#### Install rbenv

Install [rbenv via homebrew](https://github.com/rbenv/rbenv#homebrew):

```console
brew install rbenv
```

Use `rbenv` to install Ruby 3.1.2 or higher:

```console
rbenv install 3.1.2
rbenv global 3.1.2
```

Configure your shell to load `rbenv`:

```
echo 'eval "$(~/.rbenv/bin/rbenv init - zsh)"' >> ~/.zshrc
```

#### Install `bundler`

```console
gem install bundler
```

#### Install [CocoaPods](https://cocoapods.org)

```console
gem install cocoapods
```
