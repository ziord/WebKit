#!/bin/bash

# Set variables
MARCH_FLAG=""
WEBKIT_RELEASE_TYPE=$1
CPU=native
LTO_FLAG="-flto='full'"

# Install dependencies
install_packages() {
    apt-get update
    apt-get install -y "$@"
}

install_packages ca-certificates curl wget lsb-release software-properties-common gnupg gnupg1 gnupg2

# Install LLVM
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
./llvm.sh 16

# Install additional packages
install_packages \
    cmake \
    curl \
    file \
    git \
    gnupg \
    libc-dev \
    libxml2 \
    libxml2-dev \
    make \
    ninja-build \
    perl \
    python3 \
    rsync \
    ruby \
    unzip \
    bash tar gzip \
    libicu-dev

# Set environment variables
export CXX=clang++-16
export CC=clang-16
export WEBKIT_OUT_DIR=/webkitbuild

# Create output directories
mkdir -p /output/lib /output/include /output/include/JavaScriptCore /output/include/wtf /output/include/bmalloc

# Copy ICU libraries to output
cp -r /usr/lib/$(uname -m)-linux-gnu/libicu* /output/lib

# Copy files
cp -r . /webkit
cd /webkit

# Set environment variables
export CPU=${CPU}
export MARCH_FLAG=${MARCH_FLAG}
export LTO_FLAG=${LTO_FLAG}

# Build WebKit
CFLAGS="$CFLAGS $LTO_FLAG -ffat-lto-objects $MARCH_FLAG -mtune=$CPU"
CXXFLAGS="$CXXFLAGS $LTO_FLAG -ffat-lto-objects $MARCH_FLAG -mtune=$CPU"

mkdir -p /webkitbuild
cd /webkitbuild
cmake \
    -DPORT="JSCOnly" \
    -DENABLE_STATIC_JSC=ON \
    -DENABLE_BUN_SKIP_FAILING_ASSERTIONS=ON \
    -DCMAKE_BUILD_TYPE=$WEBKIT_RELEASE_TYPE \
    -DUSE_THIN_ARCHIVES=OFF \
    -DUSE_BUN_JSC_ADDITIONS=ON \
    -DENABLE_FTL_JIT=ON \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DALLOW_LINE_AND_COLUMN_NUMBER_IN_BUILTINS=ON \
    -DENABLE_SINGLE_THREADED_VM_ENTRY_SCOPE=ON \
    -G Ninja \ 
    -DCMAKE_CXX_COMPILER=$(which clang++-16) \
    -DCMAKE_C_COMPILER=$(which clang-16) \
    -DCMAKE_C_FLAGS="$CFLAGS" \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
    /webkit

cd /webkitbuild
CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" cmake --build /webkitbuild --config $WEBKIT_RELEASE_TYPE --target "jsc"
cp -r $WEBKIT_OUT_DIR/lib/*.a /output/lib
cp $WEBKIT_OUT_DIR/*.h /output/include
find $WEBKIT_OUT_DIR/JavaScriptCore/Headers/JavaScriptCore/ -name "*.h" -exec cp {} /output/include/JavaScriptCore/ \;
find $WEBKIT_OUT_DIR/JavaScriptCore/PrivateHeaders/JavaScriptCore/ -name "*.h" -exec cp {} /output/include/JavaScriptCore/ \;
cp -r $WEBKIT_OUT_DIR/WTF/Headers/wtf/ /output/include
cp -r $WEBKIT_OUT_DIR/bmalloc/Headers/bmalloc/ /output/include
mkdir -p /output/Source/JavaScriptCore
cp -r /webkit/Source/JavaScriptCore/Scripts /output/Source/JavaScriptCore
cp /webkit/Source/JavaScriptCore/create_hash_table /output/Source/JavaScriptCore

echo "Build completed."
