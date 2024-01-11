#!/bin/bash

os=$(uname -s)

if [ "$os" == "Linux" ]; then
    chmod +x linux_install.sh
    ./linux_install.sh
elif [ "$os" == "Darwin" ]; then
    chmod +x mac_install.sh
    ./mac_install.sh
else
    echo "Unsupported operating system: $os"
    exit 1
fi