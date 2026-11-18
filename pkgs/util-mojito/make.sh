#!/bin/sh
# util-mojito: mojito, lemonbar-compatible status bar for layer-shell compositors (neuswc), plus hdxi-bar
set -eu

NAME=util-mojito
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-$NAME}"
SRC="${HDX_SRC:-/hdxp/src/$NAME-src}"
PREFIX=/usr/local
URL=https://git.sr.ht/~dlm/mojito
COMMIT="5e6a307ec812ce6d7ecd66916cf4658afb19420e"
JOBS="${HDX_JOBS:-$(nproc)}"

if [ "$(id -u)" -eq 0 ]; then SU=; else SU=doas; fi

[ -d "$SRC/.git" ] || git clone -q "$URL" "$SRC"
cd "$SRC"
git fetch -q origin "$COMMIT" 2>/dev/null || git fetch -q origin
git checkout -q -f "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "$NAME: commit mismatch" >&2; exit 1; }

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

make clean >/dev/null 2>&1 || true
# the Makefile's CFLAGS has -Werror, which trips on newer gcc warnings: pass our own without it
make CC="${CC:-cc}" \
    CFLAGS="-O2 -std=c99 -D_POSIX_C_SOURCE=200809L -D_GNU_SOURCE $(pkg-config --cflags wayland-client wayland-protocols wld)" \
    -j "$JOBS"

$SU install -D -m 755 mojito "$PREFIX/bin/mojito"
$SU install -D -m 755 "$PORT/hdxi-bar" "$PREFIX/bin/hdxi-bar"
echo "$NAME installed"
