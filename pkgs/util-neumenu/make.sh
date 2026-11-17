#!/bin/sh
# util-neumenu: neumenu, dynamic menu for neuswc compositors (dmenu fork)
set -eu

NAME=util-neumenu
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-$NAME}"
SRC="${HDX_SRC:-/hdxp/src/$NAME-src}"
PREFIX=/usr/local
URL=https://git.sr.ht/~uint/neumenu
COMMIT="88d0bd8bb47a3bea4e806087b4be95af226d5bb3"
JOBS="${HDX_JOBS:-$(nproc)}"

if [ "$(id -u)" -eq 0 ]; then SU=; else SU=doas; fi

[ "$COMMIT" != FILLME ] || { echo "$NAME: COMMIT is not pinned yet (run pin.sh)" >&2; exit 1; }

[ -d "$SRC/.git" ] || git clone -q "$URL" "$SRC"
cd "$SRC"
git fetch -q origin "$COMMIT" 2>/dev/null || git fetch -q origin
git checkout -q -f "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "$NAME: commit mismatch" >&2; exit 1; }

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

make clean >/dev/null 2>&1 || true
make CC="${CC:-cc}" PREFIX="$PREFIX" -j "$JOBS"
$SU make PREFIX="$PREFIX" install
echo "$NAME installed"
