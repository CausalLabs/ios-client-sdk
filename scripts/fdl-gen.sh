#!/bin/bash

set -euox pipefail

# Script to generate Swift source from an FDL file
# This will use the local (already built) compiler
# We will provide a different script to generate from a packaged distribution (Cocoapods, SwiftPM, zip file)
# Parameter in $0: path to an FDL file
# Parameter in $1: path to a Generated.swift file to generate
if [ $# -lt 2 ]; then
    echo "$0: Usage: fdlgen.sh <path to fdl file> <path to generated.swift file>"
    exit 2
fi

# Using pushd and popd to get the absolute path
pushd "$(dirname "$1")" >/dev/null
fdl_file=$(pwd -P)/$(basename "$1")
popd >/dev/null

pushd "$(dirname "$2")" >/dev/null
swift_file=$(pwd -P)/$(basename "$2")
popd >/dev/null

# cd to the directory where the script is
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
git_root=$(git rev-parse --show-toplevel)

# generate files
echo "Generating from FDL file $fdl_file to swift at $swift_file"
$git_root/compiler/build/install/compiler/bin/compiler --swift "$swift_file" "$fdl_file"
