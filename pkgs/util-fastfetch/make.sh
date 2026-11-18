#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-util-fastfetch}"
SRC="${HDX_SRC:-/hdxp/src/util-fastfetch-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() { # need <pkg-config module> <min version>
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "util-fastfetch: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
fetch() { # fetch <url> <file> <sha256>
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "util-fastfetch: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}
mkdir -p "$SRC"
cd "$SRC"
VER=2.71.0
fetch "https://github.com/fastfetch-cli/fastfetch/archive/refs/tags/$VER.tar.gz" \
    "fastfetch-$VER.tar.gz" e71d93de41e8e4b2554c36d2ae51758112a21ecf3a8c98605a2c689251e62987

rm -rf "fastfetch-$VER"
tar xzf "fastfetch-$VER.tar.gz"
cd "fastfetch-$VER"

# fastfetch dlopen()s its libraries, so most optional modules are off to keep the build lean
cmake -S . -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DSET_TWEAK=OFF -DIS_MUSL=ON -DBUILD_FLASHFETCH=OFF -DBUILD_TESTS=OFF \
    -DENABLE_IMAGE_LOGO=OFF -DENABLE_IMAGEMAGICK7=OFF -DENABLE_IMAGEMAGICK6=OFF -DENABLE_CHAFA=OFF \
    -DENABLE_LUA=OFF -DENABLE_LIBZFS=OFF -DENABLE_RPM=OFF -DENABLE_SQLITE3=OFF \
    -DENABLE_VULKAN=OFF -DENABLE_OPENCL=OFF -DENABLE_EGL=OFF -DENABLE_GLX=OFF \
    -DENABLE_XCB_RANDR=OFF -DENABLE_XRANDR=OFF -DENABLE_VADRM=OFF -DENABLE_VAX11=OFF -DENABLE_VDPAU=OFF \
    -DENABLE_GIO=OFF -DENABLE_DCONF=OFF -DENABLE_EET=OFF -DENABLE_ELF=OFF \
    -DENABLE_DBUS=OFF -DENABLE_DRM=ON -DENABLE_WAYLAND=ON -DENABLE_ZLIB=ON
cmake --build build -j "$JOBS"
$SU cmake --install build
sync
