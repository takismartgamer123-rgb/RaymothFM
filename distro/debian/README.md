# RayMothFM on Debian 12 Bookworm

This directory contains the Debian-oriented build helper and desktop integration
for RayMothFM. The default target is the lightweight profile used by Gamma Linux.

## Design choices

- **Raylib is built as a static library.** Debian 12 Bookworm does not currently
  provide `libraylib-dev` in its package archive, so the build helper pins the
  Raylib source tag and keeps the resulting static library inside `.build/`.
  RayMothFM therefore does not need a separate Raylib shared-library package at
  runtime.
- **libvips is optional, not part of the default build.** The lightweight profile
  uses Raylib's image decoder for common image previews and bounded thumbnails.
  The advanced image converter is omitted from this profile.
- **The full image backend remains available.** Install `libvips-dev` and build
  with `WITH_VIPS=1` to restore libvips-based thumbnails, broad image-format
  support, and image conversion.
- **CRC32 has an in-tree implementation.** zlib is no longer a direct build
  dependency for checksum support. libarchive may still use zlib internally.
- **Existing core features stay native.** The file manager continues to use
  libarchive, libmagic, OpenSSL, the C++20 standard library, and XDG utilities.

## Build on Bookworm

Install the build requirements:

```sh
sudo apt update
sudo apt install build-essential cmake git pkg-config \
  libarchive-dev libmagic-dev libssl-dev \
  libgl1-mesa-dev libx11-dev libxrandr-dev \
  libxcursor-dev libxi-dev libxinerama-dev
```

Then run:

```sh
sh distro/debian/build-bookworm.sh
```

The build helper downloads Raylib tag `5.5` once, builds it statically under
`.build/debian-bookworm/`, and produces `code/raymothfm`.

To build the optional full image backend instead:

```sh
sudo apt install libvips-dev
PKG_CONFIG_PATH="$PWD/.build/debian-bookworm/raylib-prefix/lib/pkgconfig" \
  make -C code clean all WITH_VIPS=1
```

## Runtime expectations

The default profile still needs the runtime libraries corresponding to
libarchive, libmagic, OpenSSL, Mesa/OpenGL, and the X11 stack. Optional external
archive helpers such as 7-Zip, zstd, and xz should be installed only when their
specific formats or operations are required.

The lightweight profile intentionally trades broad image-conversion support for
a smaller dependency surface. Raylib's decoder does not promise support for
every format that libvips can load; unsupported files should fail gracefully
rather than pull the full image-processing stack into the base installation.
