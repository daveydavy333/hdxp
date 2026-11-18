#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-util-strace}"
SRC="${HDX_SRC:-/hdxp/src/util-strace-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() { # need <pkg-config module> <min version>
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "util-strace: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
# fetch <url> <file> <sha256>; an empty sha means "unpinned": print it and stop,
# unless HDX_TOFU=1 (then trust this first download)
fetch() {
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    if [ -z "$3" ]; then
        echo "util-strace: UNPINNED $2 sha256=$(sha256sum "$2" | cut -d' ' -f1)" >&2
        [ "${HDX_TOFU:-0}" = 1 ] || { echo "util-strace: re-run with HDX_TOFU=1 to accept, then pin this sha in make.sh" >&2; exit 1; }
        return 0
    fi
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "util-strace: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}
mkdir -p "$SRC"
cd "$SRC"

VER=7.3
fetch "https://github.com/strace/strace/releases/download/v$VER/strace-$VER.tar.xz" \
    "strace-$VER.tar.xz" 529634c40910895a9a1f3c5c1e65da2ca9ed72fb158dfc4bcc89efdf05e39b72
rm -rf "strace-$VER"
tar xf "strace-$VER.tar.xz"
cd "strace-$VER"
./configure --prefix=/usr/local --enable-mpers=no --without-libunwind --without-libdw
make -j "$JOBS"
$SU make install
sync
