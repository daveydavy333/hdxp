#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-util-pciutils}"
SRC="${HDX_SRC:-/hdxp/src/util-pciutils-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() { # need <pkg-config module> <min version>
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "util-pciutils: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
# fetch <url> <file> <sha256>; an empty sha means "unpinned": print it and stop,
# unless HDX_TOFU=1 (then trust this first download)
fetch() {
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    if [ -z "$3" ]; then
        echo "util-pciutils: UNPINNED $2 sha256=$(sha256sum "$2" | cut -d' ' -f1)" >&2
        [ "${HDX_TOFU:-0}" = 1 ] || { echo "util-pciutils: re-run with HDX_TOFU=1 to accept, then pin this sha in make.sh" >&2; exit 1; }
        return 0
    fi
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "util-pciutils: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}
mkdir -p "$SRC"
cd "$SRC"

VER=3.15.0
fetch "https://github.com/pciutils/pciutils/archive/refs/tags/v$VER.tar.gz" \
    "pciutils-$VER.tar.gz" 06f467642057599acf396bc17340452fac3308f1e08be19e0c32587e42d7017b
rm -rf "pciutils-$VER"
tar xzf "pciutils-$VER.tar.gz"
cd "pciutils-$VER"
OPTS="PREFIX=/usr/local SHARED=no ZLIB=no DNS=no LIBKMOD=no HWDB=no"
make -j "$JOBS" $OPTS
$SU make install $OPTS
sync
