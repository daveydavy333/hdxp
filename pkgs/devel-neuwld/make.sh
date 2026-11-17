#!/bin/sh
# devel-neuwld: neuwld, drawing library for wayland (wayland.fyi fork of wld)
set -eu

NAME=devel-neuwld
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-$NAME}"
SRC="${HDX_SRC:-/hdxp/src/$NAME-src}"
PREFIX=/usr/local
URL=https://git.sr.ht/~shrub900/neuwld
COMMIT="712fa71be579f3796b3cd500de87c736a8617dd7"
JOBS="${HDX_JOBS:-$(nproc)}"

if [ "$(id -u)" -eq 0 ]; then SU=; else SU=doas; fi

[ -d "$SRC/.git" ] || git clone -q "$URL" "$SRC"
cd "$SRC"
git fetch -q origin "$COMMIT" 2>/dev/null || git fetch -q origin
git checkout -q -f "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "$NAME: commit mismatch" >&2; exit 1; }

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

rm -rf build
# drivers=[] : only the dumb-buffer drm path (run with WLD_DRM_DUMB=1), no libdrm_intel/nouveau
meson setup build \
    --prefix="$PREFIX" --libdir=lib --buildtype=release \
    -Dwayland=enabled -Ddrm=enabled -Ddoxygen=disabled '-Ddrivers=[]'
meson compile -C build -j "$JOBS"
$SU meson install -C build

pkg-config --modversion wld >/dev/null
echo "$NAME installed"
