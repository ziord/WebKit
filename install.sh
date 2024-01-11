#!/bin/bash

os=$(uname -s)

BUILD_TYPE="${1:-Release}"
echo "Build Type: $BUILD_TYPE"

if [ "$os" == "Linux" ]; then
    chmod +x linux_install.sh
    ./linux_install.sh "$BUILD_TYPE"
elif [ "$os" == "Darwin" ]; then
    chmod +x mac_install.sh
    ./mac_install.sh "$BUILD_TYPE"
else
    echo "Unsupported operating system: $os"
    exit 1
fi