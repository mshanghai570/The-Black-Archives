#!/usr/bin/env bash
# Build ONE slice of the patched Mirage sdcpp static lib, disk-conscious:
# stashes the final libmirage-sdcpp.a, then deletes the cmake build dir.
# Usage: build_mirage_slice.sh device|sim  STASH_DIR
set -euo pipefail

SLICE="${1:?slice: device|sim}"
STASH="${2:?stash dir}"
ROOT="/Users/michaelshingara/Downloads/the-black-archives"
SD_DIR="$ROOT/Vendor/Mirage/Sources/CMirage/vendor/sd-cpp"
WRAP_DIR="$ROOT/Vendor/Mirage/Sources/CMirage"
SYMS="$ROOT/Vendor/Mirage/Scripts/mirage-exported-symbols.txt"
BD="$ROOT/.build-xcf/$SLICE"

case "$SLICE" in
  device)
    SYSROOT="$(xcrun -sdk iphoneos --show-sdk-path)"
    TARGET="arm64-apple-ios17.0"
    PLATFORM_FLAG="-platform_version ios 17.0 17.0"
    ;;
  sim)
    SYSROOT="$(xcrun -sdk iphonesimulator --show-sdk-path)"
    TARGET="arm64-apple-ios17.0-simulator"
    PLATFORM_FLAG="-platform_version ios-simulator 17.0 17.0"
    ;;
  *)
    echo "bad slice $SLICE" >&2; exit 1
    ;;
esac

rm -rf "$BD" "$STASH/$SLICE"
mkdir -p "$BD" "$STASH/$SLICE"

echo "==> [$SLICE] configuring sd.cpp"
cmake -S "$SD_DIR" -B "$BD" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DSD_METAL=ON \
    -DGGML_METAL=ON \
    -DGGML_METAL_EMBED_LIBRARY=ON \
    -DSD_BUILD_EXAMPLES=OFF \
    -DSD_BUILD_SERVER=OFF \
    -DSD_BUILD_SHARED_LIBS=OFF \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$SYSROOT" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0

echo "==> [$SLICE] ninja stable-diffusion"
ninja -C "$BD" stable-diffusion

echo "==> [$SLICE] compiling patched MirageC.cpp"
clang++ -c -std=c++17 -O2 \
    -isysroot "$SYSROOT" \
    -target "$TARGET" \
    -I"$WRAP_DIR/include" \
    -I"$SD_DIR/include" \
    -I"$SD_DIR/ggml/include" \
    "$WRAP_DIR/sd/MirageC.cpp" \
    -o "$BD/MirageC.o"

echo "==> [$SLICE] partial-linking (symbol hiding)"
rm -f "$BD/libmirage-sdcpp-prelinked.o"
ld -r -arch arm64 $PLATFORM_FLAG \
    -exported_symbols_list "$SYMS" \
    -force_load "$BD/libstable-diffusion.a" \
    -force_load "$BD/ggml/src/libggml.a" \
    -force_load "$BD/ggml/src/libggml-base.a" \
    -force_load "$BD/ggml/src/libggml-cpu.a" \
    -force_load "$BD/ggml/src/ggml-metal/libggml-metal.a" \
    -force_load "$BD/ggml/src/ggml-blas/libggml-blas.a" \
    "$BD/MirageC.o" \
    -o "$BD/libmirage-sdcpp-prelinked.o"

echo "==> [$SLICE] wrapping static lib"
libtool -static -o "$STASH/$SLICE/libmirage-sdcpp.a" "$BD/libmirage-sdcpp-prelinked.o"

echo "==> [$SLICE] verifying exported symbols"
EXPORTED=$(nm -gU "$STASH/$SLICE/libmirage-sdcpp.a" 2>/dev/null | grep -cE " T _mirage_")
LEAK=$(nm -gU "$STASH/$SLICE/libmirage-sdcpp.a" 2>/dev/null | grep -cE " T _ggml_metal_library_init$")
echo "    mirage_* exported = $EXPORTED, leaked ggml_metal_library_init = $LEAK"
if [ "$EXPORTED" = "0" ] || [ "$LEAK" != "0" ]; then
    echo "ERROR: symbol hiding check failed" >&2
    exit 1
fi

echo "==> [$SLICE] cleaning build dir"
rm -rf "$BD"
ls -lh "$STASH/$SLICE/libmirage-sdcpp.a"
echo "==> [$SLICE] DONE"
