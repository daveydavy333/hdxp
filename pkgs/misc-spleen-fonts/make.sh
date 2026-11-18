#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-misc-spleen-fonts}"
SRC="${HDX_SRC:-/hdxp/src/misc-spleen-fonts-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() { # need <pkg-config module> <min version>
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "misc-spleen-fonts: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
# fetch <url> <file> <sha256>; an empty sha means "unpinned": print it and stop,
# unless HDX_TOFU=1 (then trust this first download)
fetch() {
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    if [ -z "$3" ]; then
        echo "misc-spleen-fonts: UNPINNED $2 sha256=$(sha256sum "$2" | cut -d' ' -f1)" >&2
        [ "${HDX_TOFU:-0}" = 1 ] || { echo "misc-spleen-fonts: re-run with HDX_TOFU=1 to accept, then pin this sha in make.sh" >&2; exit 1; }
        return 0
    fi
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "misc-spleen-fonts: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}
mkdir -p "$SRC"
cd "$SRC"

install_fonts() { # install_fonts <dir> <files...>
    d="/usr/local/share/fonts/$1"; shift
    $SU mkdir -p "$d"
    for f in "$@"; do $SU install -m644 "$f" "$d/"; done
    if command -v fc-cache >/dev/null 2>&1; then $SU fc-cache -f "$d" || true; fi
}
VER=2.3.0
fetch "https://github.com/fcambus/spleen/releases/download/$VER/spleen-$VER.tar.gz" \
    "spleen-$VER.tar.gz" 7b5729aaa8378e9987eccdb98c644180a875dcc22ee7258d8be3791238b87a02
rm -rf "spleen-$VER"
tar xzf "spleen-$VER.tar.gz"
cd "spleen-$VER"
# bitmap fonts: pcf for fontconfig/X-style users, bdf for conversion (e.g. to psf for the console)
install_fonts spleen spleen-*.pcf spleen-*.bdf
sync
