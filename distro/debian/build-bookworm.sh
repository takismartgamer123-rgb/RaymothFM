#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/.build/debian-bookworm}"
RAYLIB_DIR="${RAYLIB_DIR:-$BUILD_DIR/raylib-src}"
RAYLIB_BUILD="${RAYLIB_BUILD:-$BUILD_DIR/raylib-build}"
RAYLIB_PREFIX="${RAYLIB_PREFIX:-$BUILD_DIR/raylib-prefix}"
RAYLIB_TAG="${RAYLIB_TAG:-5.5}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)}"

for tool in git cmake make g++ pkg-config; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "Missing build tool: $tool" >&2
        exit 1
    }
done

mkdir -p "$BUILD_DIR"

if [ ! -f "$RAYLIB_DIR/CMakeLists.txt" ]; then
    git clone --depth 1 --branch "$RAYLIB_TAG" \
        https://github.com/raysan5/raylib.git "$RAYLIB_DIR"
fi

cmake -S "$RAYLIB_DIR" -B "$RAYLIB_BUILD" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$RAYLIB_PREFIX" \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DUSE_EXTERNAL_GLFW=OFF

cmake --build "$RAYLIB_BUILD" --parallel "$JOBS"
cmake --install "$RAYLIB_BUILD"

export PKG_CONFIG_PATH="$RAYLIB_PREFIX/lib/pkgconfig:$RAYLIB_PREFIX/lib/x86_64-linux-gnu/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

for package in raylib libarchive libmagic openssl; do
    pkg-config --exists "$package" || {
        echo "pkg-config could not find: $package" >&2
        exit 1
    }
done

make -C "$ROOT/code" clean
make -C "$ROOT/code" --jobs="$JOBS" WITH_VIPS=0

echo
echo "Built: $ROOT/code/raymothfm"
echo "Profile: lightweight (no libvips, static Raylib)"
