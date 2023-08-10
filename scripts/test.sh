#!/bin/bash
set -euox pipefail

# cd to the directory where the script is
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# cd back one directory to iOS root
cd ..

DEST="platform=iOS Simulator,name=iPhone 14,OS=latest"

make compiler

echo "Running unit tests..."
xcodebuild clean test \
    -project CausalLabsSDK.xcodeproj \
    -scheme CausalLabsSDK \
    -destination "$DEST" | xcpretty

xcodebuild clean build \
    -project Example/ExampleApp.xcodeproj \
    -scheme ExampleApp \
    -destination "$DEST" | xcpretty

make lint

# some iOS only developers won't have the server built and running
# TODO: set up a shared environment to hit for these tests
if [ -n "${CAUSAL_EMAIL:-}" ]; then
    ./scripts/start-servers.sh

    xcodebuild clean test \
        -project CausalLabsSDK.xcodeproj \
        -scheme RealServerTests \
        -destination "$DEST" | xcpretty

    # shutdown servers
    ../../regression/kill-all.sh
fi

echo "All iOS tests passed!"
