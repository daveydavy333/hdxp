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

[ -d "$SRC/.git" ] || git clone -q "$URL" "$SRC"
cd "$SRC"
git fetch -q origin "$COMMIT" 2>/dev/null || git fetch -q origin
git checkout -q -f "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "$NAME: commit mismatch" >&2; exit 1; }

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

# neumenu's Makefile expects swc's protocol file at /usr/share/swc/swc.xml;
# neuswc installs it under the prefix (or, failing that, it is in the neuswc sources)
SWCXML=
for d in "$PREFIX/share" /usr/share "${HDX_SRC_ROOT:-/hdxp/src}/devel-neuswc-src/protocol"; do
    [ -d "$d" ] || continue
    SWCXML="$(find "$d" -name swc.xml 2>/dev/null | head -n 1)"
    [ -z "$SWCXML" ] || break
done
[ -n "$SWCXML" ] || { echo "$NAME: swc.xml not found (is devel-neuswc installed?)" >&2; exit 1; }
for f in Makefile config.mk; do
    [ -f "$f" ] && sed -i "s|/usr/share/swc/swc.xml|$SWCXML|g" "$f"
done

make clean >/dev/null 2>&1 || true
make CC="${CC:-cc}" PREFIX="$PREFIX" -j "$JOBS"
$SU make PREFIX="$PREFIX" install
echo "$NAME installed"
