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
if [ ! -e llvm.sh ]
then
    wget https://apt.llvm.org/llvm.sh
    chmod +x llvm.sh
fi
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
export WEBKIT_SRC_DIR="$PWD"
export WEBKIT_BUILD_DIR="$PWD/WebKitBuild/webkitbuild"
export OUTPUT_DIR="$PWD/WebKitBuild/bun-webkit"

# Create output directories
mkdir -p $OUTPUT_DIR/lib $OUTPUT_DIR/include $OUTPUT_DIR/include/JavaScriptCore $OUTPUT_DIR/include/wtf $OUTPUT_DIR/include/bmalloc

# Copy ICU libraries to output
cp -r /usr/lib/$(uname -m)-linux-gnu/libicu* $OUTPUT_DIR/lib

# Set environment variables
export CPU=${CPU}
export MARCH_FLAG=${MARCH_FLAG}
export LTO_FLAG=${LTO_FLAG}

# Build WebKit
CFLAGS="$CFLAGS $LTO_FLAG -ffat-lto-objects $MARCH_FLAG -mtune=$CPU"
CXXFLAGS="$CXXFLAGS $LTO_FLAG -ffat-lto-objects $MARCH_FLAG -mtune=$CPU"

mkdir -p "$WEBKIT_BUILD_DIR"
cd "$WEBKIT_BUILD_DIR"
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
    "$WEBKIT_SRC_DIR"

cd "$WEBKIT_BUILD_DIR"
CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" cmake --build "$WEBKIT_BUILD_DIR" --config $WEBKIT_RELEASE_TYPE --target "jsc"
cp -r $WEBKIT_BUILD_DIR/lib/*.a $OUTPUT_DIR/lib
cp $WEBKIT_BUILD_DIR/*.h $OUTPUT_DIR/include
find $WEBKIT_BUILD_DIR/JavaScriptCore/Headers/JavaScriptCore/ -name "*.h" -exec cp {} $OUTPUT_DIR/include/JavaScriptCore/ \;
find $WEBKIT_BUILD_DIR/JavaScriptCore/PrivateHeaders/JavaScriptCore/ -name "*.h" -exec cp {} $OUTPUT_DIR/include/JavaScriptCore/ \;
cp -r $WEBKIT_BUILD_DIR/WTF/Headers/wtf/ $OUTPUT_DIR/include
cp -r $WEBKIT_BUILD_DIR/bmalloc/Headers/bmalloc/ $OUTPUT_DIR/include
mkdir -p $OUTPUT_DIR/Source/JavaScriptCore
cp -r "$WEBKIT_SRC_DIR"/Source/JavaScriptCore/Scripts $OUTPUT_DIR/Source/JavaScriptCore
cp "$WEBKIT_SRC_DIR"/Source/JavaScriptCore/create_hash_table $OUTPUT_DIR/Source/JavaScriptCore

echo "Build completed."
