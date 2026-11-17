#!/bin/sh
# util-wawa: wawa, simple wallpaper setter for layer-shell compositors (neuswc)
set -eu

NAME=util-wawa
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-$NAME}"
SRC="${HDX_SRC:-/hdxp/src/$NAME-src}"
PREFIX=/usr/local
URL=https://codeberg.org/sewn/wawa.git
COMMIT="6840ee8756d26ef05756a6ae90789c4b71dd143d"
JOBS="${HDX_JOBS:-$(nproc)}"

if [ "$(id -u)" -eq 0 ]; then SU=; else SU=doas; fi

[ -d "$SRC/.git" ] || git clone -q "$URL" "$SRC"
cd "$SRC"
git fetch -q origin "$COMMIT" 2>/dev/null || git fetch -q origin
git checkout -q -f "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "$NAME: commit mismatch" >&2; exit 1; }

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

make clean >/dev/null 2>&1 || true
# gcc 15 defaults to C23, where wawa's `noop() {}` no longer converts to the listener callbacks
make CC="${CC:-cc} -std=gnu17" -j "$JOBS"

$SU install -D -m 755 wawa "$PREFIX/bin/wawa"
echo "$NAME installed"
