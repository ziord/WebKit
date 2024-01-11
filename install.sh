#!/bin/bash

os=$(uname -s)

RELEASE_TYPE="${$1:-Release}"

if [ "$os" == "Linux" ]; then
    chmod +x linux_install.sh
    ./linux_install.sh $RELEASE_TYPE
elif [ "$os" == "Darwin" ]; then
    chmod +x mac_install.sh
    ./mac_install.sh $RELEASE_TYPE
else
    echo "Unsupported operating system: $os"
    exit 1
fi