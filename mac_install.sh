#!/bin/bash

set -euxo pipefail

# installs webkit for bun

THIS_DIR=$(pwd)

# Set default values for environment variables that are not set.
CMAKE_C_COMPILER="$(which clang-16)"
CMAKE_CXX_COMPILER="$(dirname ${CMAKE_C_COMPILER})"/clang++
CMAKE_C_FLAGS=${CMAKE_C_FLAGS:-}
CMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS:-}
CMAKE_BUILD_TYPE=Release
BUILD_DIR="$(dirname "$(readlink -f "$0")")"/WebKitBuild
PACKAGE_JSON_LABEL=${PACKAGE_JSON_LABEL:-bun-webkit-$CMAKE_BUILD_TYPE}
PACKAGE_JSON_ARCH=$(arch)
GITHUB_REPOSITORY=ziord/WebKit
GIT_SHA=$(git rev-parse --verify HEAD)

rm -rf $BUILD_DIR/Release $BUILD_DIR/bun-webkit $BUILD_DIR/bun-webkit.tar.gz
mkdir -p $BUILD_DIR/Release
cd $BUILD_DIR/Release
cmake \
    -DPORT="JSCOnly" \
    -DENABLE_STATIC_JSC=ON \
    -DENABLE_SINGLE_THREADED_VM_ENTRY_SCOPE=ON \
    -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
    -DENABLE_BUN_SKIP_FAILING_ASSERTIONS=ON \
    -DUSE_THIN_ARCHIVES=OFF \
    -DENABLE_FTL_JIT=ON \
    -DCMAKE_C_COMPILER="$CMAKE_C_COMPILER" \
    -DCMAKE_CXX_COMPILER="$CMAKE_CXX_COMPILER" \
    -DCMAKE_C_FLAGS="$CMAKE_C_FLAGS" \
    -DCMAKE_CXX_FLAGS="$CMAKE_CXX_FLAGS" \
    -DUSE_BUN_JSC_ADDITIONS=ON \
    -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld" \
    -DCMAKE_AR=$(which llvm-ar) \
    -DCMAKE_RANLIB=$(which llvm-ranlib) \
    -DALLOW_LINE_AND_COLUMN_NUMBER_IN_BUILTINS=ON \
    -G Ninja \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
    -DPTHREAD_JIT_PERMISSIONS_API=1 \
    -DUSE_PTHREAD_JIT_PERMISSIONS_API=ON \
    -DENABLE_REMOTE_INSPECTOR=ON \
    $THIS_DIR \
    $BUILD_DIR/Release &&
    cmake --build $BUILD_DIR/Release --config $CMAKE_BUILD_TYPE --target jsc
mkdir -p $BUILD_DIR/bun-webkit/lib $BUILD_DIR/bun-webkit/include $BUILD_DIR/bun-webkit/include/JavaScriptCore $BUILD_DIR/bun-webkit/include/wtf $BUILD_DIR/bun-webkit/include/bmalloc
cp $BUILD_DIR/Release/lib/* $BUILD_DIR/bun-webkit/lib
cp -r $BUILD_DIR/Release/cmakeconfig.h $BUILD_DIR/bun-webkit/include/cmakeconfig.h
echo "#define BUN_WEBKIT_VERSION \"$GIT_SHA\"" >>$BUILD_DIR/bun-webkit/include/cmakeconfig.h
cp -r $BUILD_DIR/Release/WTF/Headers/wtf $BUILD_DIR/bun-webkit/include
cp -r $BUILD_DIR/Release/ICU/Headers/* $BUILD_DIR/bun-webkit/include
cp -r $BUILD_DIR/Release/bmalloc/Headers/bmalloc $BUILD_DIR/bun-webkit/include
cp $BUILD_DIR/Release/JavaScriptCore/Headers/JavaScriptCore/* $BUILD_DIR/bun-webkit/include/JavaScriptCore
cp $BUILD_DIR/Release/JavaScriptCore/PrivateHeaders/JavaScriptCore/* $BUILD_DIR/bun-webkit/include/JavaScriptCore
mkdir -p $BUILD_DIR/bun-webkit/Source/JavaScriptCore
cp -r $THIS_DIR/Source/JavaScriptCore/Scripts $BUILD_DIR/bun-webkit/Source/JavaScriptCore
cp $THIS_DIR/Source/JavaScriptCore/create_hash_table $BUILD_DIR/bun-webkit/Source/JavaScriptCore
echo "{ \"name\": \"$PACKAGE_JSON_LABEL\", \"version\": \"0.0.1-$GIT_SHA\", \"os\": [\"darwin\"], \"cpu\": [\"$PACKAGE_JSON_ARCH\"], \"repository\": \"https://github.com/$GITHUB_REPOSITORY\" }" >$BUILD_DIR/bun-webkit/package.json

echo "Build completed."
