#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-util-havoc}"
SRC="${HDX_SRC:-/hdxp/src/util-havoc-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() { # need <pkg-config module> <min version>
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "util-havoc: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
# fetch <url> <file> <sha256>; an empty sha means "unpinned": print it and stop,
# unless HDX_TOFU=1 (then trust this first download)
fetch() {
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    if [ -z "$3" ]; then
        echo "util-havoc: UNPINNED $2 sha256=$(sha256sum "$2" | cut -d' ' -f1)" >&2
        [ "${HDX_TOFU:-0}" = 1 ] || { echo "util-havoc: re-run with HDX_TOFU=1 to accept, then pin this sha in make.sh" >&2; exit 1; }
        return 0
    fi
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "util-havoc: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}
mkdir -p "$SRC"
cd "$SRC"

VER=0.7.0
fetch "https://github.com/ii8/havoc/archive/refs/tags/$VER.tar.gz" \
    "havoc-$VER.tar.gz" b4f819bfc3b0f8ea967018948dbf3a71f174a02886d00ee16121739fcd140d6f
need wayland-client 1.20
need wayland-cursor 1.20
need wayland-protocols 1.21
need xkbcommon 0.5
rm -rf "havoc-$VER"
tar xzf "havoc-$VER.tar.gz"
cd "havoc-$VER"
make -j "$JOBS" PREFIX=/usr/local
$SU make install PREFIX=/usr/local
# optional config: ~/.config/havoc.cfg, or the sample as a starting point
$SU mkdir -p /usr/local/share/havoc
$SU install -m644 havoc.cfg /usr/local/share/havoc/havoc.cfg.sample
sync
