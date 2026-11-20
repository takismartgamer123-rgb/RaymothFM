#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
VERSION="$(cat "$ROOT/code/VERSION")"
REVISION="${DEBIAN_REVISION:-1~bookworm1}"
ARCH="${DEB_HOST_ARCH:-$(dpkg --print-architecture)}"
PACKAGE_VERSION="${VERSION}-${REVISION}"
WORK_DIR="${PACKAGE_WORK_DIR:-$ROOT/.build/debian-package}"
STAGE="$WORK_DIR/root"
PKG="$WORK_DIR/package"
OUT_DIR="${OUTPUT_DIR:-$ROOT/dist}"
OUT="$OUT_DIR/raymothfm_${PACKAGE_VERSION}_${ARCH}.deb"

for tool in make dpkg dpkg-deb dpkg-shlibdeps; do
    command -v "$tool" >/dev/null 2>&1 || { echo "Missing packaging tool: $tool (install dpkg-dev if needed)" >&2; exit 1; }
done

rm -rf "$WORK_DIR"
mkdir -p "$STAGE" "$PKG/DEBIAN" "$OUT_DIR" "$WORK_DIR/debian"
DESTDIR="$STAGE" make -C "$ROOT/code" install

test -x "$STAGE/usr/bin/raymothfm"
test -s "$STAGE/usr/share/applications/raymothfm.desktop"
test -s "$STAGE/usr/share/doc/raymothfm/copyright"
test -s "$STAGE/usr/share/doc/raymothfm/RAYLIB-5.5.txt"
test -s "$STAGE/usr/share/doc/raymothfm/GLFW.txt"
test -s "$STAGE/usr/share/doc/raymothfm/NOTICE"
install -Dm644 "$ROOT/README.md" "$STAGE/usr/share/doc/raymothfm/README.md"
cp -a "$STAGE/." "$PKG/"

# dpkg-shlibdeps requires debian/control in its current working directory.
cat > "$WORK_DIR/debian/control" <<EOF
Source: raymothfm
Section: utils
Priority: optional
Maintainer: Taki (Gamma Linux packaging) <founder@mail.gamma-linux.is-local.org>
Standards-Version: 4.6.2

Package: raymothfm
Architecture: $ARCH
Description: Lightweight graphical file manager
 RayMothFM is a native graphical file manager.
EOF

SHLIBS_OUTPUT="$(cd "$WORK_DIR" && DEB_HOST_ARCH="$ARCH" dpkg-shlibdeps -O -e"$PKG/usr/bin/raymothfm")"
DEPENDS="$(printf '%s\n' "$SHLIBS_OUTPUT" | sed -n 's/^shlibs:Depends=//p' | head -n 1)"
if [ -z "$DEPENDS" ]; then
    echo "dpkg-shlibdeps did not return runtime dependencies:" >&2
    printf '%s\n' "$SHLIBS_OUTPUT" >&2
    exit 1
fi

cat > "$PKG/DEBIAN/control" <<EOF
Package: raymothfm
Version: $PACKAGE_VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: Taki (Gamma Linux packaging) <founder@mail.gamma-linux.is-local.org>
Depends: $DEPENDS
Homepage: https://github.com/HalanoSiblee/RayMothFM
Description: Lightweight graphical file manager
 RayMothFM is a native graphical file manager. This Debian package is built
 from the Gamma Bookworm Lite integration while preserving upstream project
 attribution and license notices.
EOF
chmod 0755 "$PKG/DEBIAN"
chmod 0644 "$PKG/DEBIAN/control"
dpkg-deb --root-owner-group --build "$PKG" "$OUT" >/dev/null
echo "Package created: $OUT"
dpkg-deb --info "$OUT"
