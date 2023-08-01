#!/bin/zsh

# Generates documentation using SourceDocs and checks for installation.
# SourceDocs: https://github.com/SourceDocs/SourceDocs

set -euxo pipefail

VERSION="2.0.1"
INSTALL="brew install sourcedocs"
DOC_PATH="../../docs/docs/reference/iOS"
CATEGORY_FILE="_category_.yml"

if which sourcedocs >/dev/null; then
    FOUND=$(sourcedocs version)
    if [ "$FOUND" != "SourceDocs v$VERSION" ]; then
        echo "
        Warning: incorrect SourceDocs installed! Please upgrade.
        Expected: $VERSION
        Found: $FOUND

        Install: $INSTALL
        "
        exit 1
    fi

    # copy the category file to a safe place
    TMP_FILE=$(mktemp -t category.yml.XXXXXXXXXX)
    cp $DOC_PATH/$CATEGORY_FILE $TMP_FILE

    sourcedocs generate \
        --clean \
        --output-folder $DOC_PATH \
        --reproducible-docs \
        --min-acl public \
        -- -scheme CausalLabsSDK

    # re-add the category file
    mv $TMP_FILE $DOC_PATH/$CATEGORY_FILE
else
    echo "
    Error: SourceDocs not installed!

    Install: $INSTALL
    "
    exit 1
fi

exit
