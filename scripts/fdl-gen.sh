#!/bin/bash
set -euox pipefail

# Script to generate Swift source from an FDL file.
# Uses the locally build compiler in `ios/bin/`.
#
# Parameter $0: path to FDL file.
# Parameter $1: path to Swift file.
if [ $# -lt 2 ]; then
    echo "Invalid usage."
    echo "$0: Usage: ./fdlgen.sh PATH_TO_FDL_FILE PATH_TO_SWIFT_FILE"
    exit 2
fi

# Get the absolute path to FDL file.
pushd "$(dirname "$1")" >/dev/null
fdl_file=$(pwd -P)/$(basename "$1")
popd >/dev/null

# Get the absolute path to Swift file.
pushd "$(dirname "$2")" >/dev/null
swift_file=$(pwd -P)/$(basename "$2")
popd >/dev/null

# cd to the script's directory
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
git_root=$(git rev-parse --show-toplevel)

# Generate files
echo "Generating files..."
echo "From FDL: $fdl_file"
echo "To Swift: $swift_file"

../compiler/bin/compiler --swift "$swift_file" "$fdl_file"

echo "Finished."
