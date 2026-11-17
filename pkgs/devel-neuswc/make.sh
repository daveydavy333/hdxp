#!/bin/sh
# devel-neuswc: neuswc, wayland compositor library (wayland.fyi fork of swc), plus setuid swc-launch
set -eu

NAME=devel-neuswc
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-$NAME}"
SRC="${HDX_SRC:-/hdxp/src/$NAME-src}"
PREFIX=/usr/local
URL=https://git.sr.ht/~shrub900/neuswc
COMMIT="050726e3aa6f084512516e8d563fddbacb8dc2de"
JOBS="${HDX_JOBS:-$(nproc)}"

if [ "$(id -u)" -eq 0 ]; then SU=; else SU=doas; fi

[ -d "$SRC/.git" ] || git clone -q "$URL" "$SRC"
cd "$SRC"
git fetch -q origin "$COMMIT" 2>/dev/null || git fetch -q origin
git checkout -q -f "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "$NAME: commit mismatch" >&2; exit 1; }

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

rm -rf build
# release matters: the default debug buildtype turns on swc's debug logging
meson setup build \
    --prefix="$PREFIX" --libdir=lib --buildtype=release \
    -Dvideo=drm -Dinput=libinput -Dudev=enabled -Dxwayland=disabled \
    -Dextra=true -Dexample=false
meson compile -C build -j "$JOBS"
$SU meson install -C build

# swc-launch opens the drm device and switches VTs, so it must be setuid root
$SU chown root:root "$PREFIX/bin/swc-launch"
$SU chmod 4755 "$PREFIX/bin/swc-launch"

pkg-config --modversion swc >/dev/null
echo "$NAME installed"
