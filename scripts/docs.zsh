#!/bin/zsh

# Generates documentation using jazzy and checks for installation.
# Jazzy: https://github.com/realm/jazzy/releases/latest

set -euxo pipefail

VERSION="0.14.3"

FOUND=$(jazzy --version)
LINK="https://github.com/realm/jazzy"
INSTALL="gem install jazzy"

if which jazzy >/dev/null; then
    jazzy \
        --clean \
        --author "Causal Labs, Inc." \
        --author_url "https://www.causallabs.io" \
        --github_url "https://github.com/CausalLabs/ios-client-sdk" \
        --build-tool-arguments -scheme,CausalLabsSDK \
        --module "CausalLabsSDK" \
        --source-directory . \
        --readme "README.md" \
        --documentation "Guides/*.md" \
        --output docs/
else
    echo "
    Error: Jazzy not installed!

    Download: $LINK
    Install: $INSTALL
    "
    exit 1
fi

if [ "$FOUND" != "jazzy version: $VERSION" ]; then
    echo "
    Warning: incorrect Jazzy installed! Please upgrade.
    Expected: $VERSION
    Found: $FOUND

    Download: $LINK
    Install: $INSTALL
    "
fi

exit
