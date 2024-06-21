#!/bin/bash
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

source "$SCRIPT_DIR/functions.sh"

set -xeuo pipefail

BUILD="$(mktemp -d)"
ARTIFACT="$WORKSPACE/build"

cd "$BUILD" || exit 1

mkdir -p "$BUILD/output"
mkdir -p "$ARTIFACT"

case "${1:-}" in
make)
    cmake "$WORKSPACE"
    make -j
    copy-license "$BUILD/output"
    zip -r -j "$ARTIFACT/lpac-$KERNEL-$MATCHINE.zip" output/*
    ;;
debian)
    cmake "$WORKSPACE" -DCPACK_GENERATOR=DEB
    make -j package
    copy-license "$BUILD/output"
    cp lpac_*.deb "$ARTIFACT"
    ;;
mingw)
    cmake "$WORKSPACE" -DCMAKE_TOOLCHAIN_FILE=./cmake/linux-mingw64.cmake
    make -j
    copy-license "$BUILD/output"
    copy-curl-win "$BUILD/output"
    zip -r -j "$ARTIFACT/lpac-windows-x86_64-mingw.zip" output/*
    ;;
woa-mingw)
    TOOLCHAIN="$(download "$MINGW32_TOOLCHAIN_BLOB")"
    cmake "$WORKSPACE" -DCMAKE_TOOLCHAIN_FILE=./cmake/linux-mingw64-woa.cmake "-DTOOLCHAIN_BIN_PATH=$TOOLCHAIN/bin"
    make -j
    rm -rf "$TOOLCHAIN"
    copy-license "$BUILD/output"
    copy-curl-woa "$BUILD/output"
    zip -r -j "$ARTIFACT/lpac-windows-arm64-mingw.zip" output/*
    ;;
woa-zig)
    cmake "$WORKSPACE" -DCMAKE_TOOLCHAIN_FILE=./cmake/aarch64-windows-zig.cmake
    make -j
    copy-license "$BUILD/output"
    copy-curl-woa "$BUILD/output"
    zip -r -j "$ARTIFACT/lpac-windows-arm64-zig.zip" output/*
    ;;
*)
    echo "Usage: $0 {make,debian,mingw,woa-mingw,woa-zig}"
    exit 1
    ;;
esac

rm -rf "$BUILD"
