#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-misc-liberation-fonts}"
SRC="${HDX_SRC:-/hdxp/src/misc-liberation-fonts-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() { # need <pkg-config module> <min version>
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "misc-liberation-fonts: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
# fetch <url> <file> <sha256>; an empty sha means "unpinned": print it and stop,
# unless HDX_TOFU=1 (then trust this first download)
fetch() {
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    if [ -z "$3" ]; then
        echo "misc-liberation-fonts: UNPINNED $2 sha256=$(sha256sum "$2" | cut -d' ' -f1)" >&2
        [ "${HDX_TOFU:-0}" = 1 ] || { echo "misc-liberation-fonts: re-run with HDX_TOFU=1 to accept, then pin this sha in make.sh" >&2; exit 1; }
        return 0
    fi
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "misc-liberation-fonts: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}
mkdir -p "$SRC"
cd "$SRC"

install_fonts() { # install_fonts <dir> <files...>
    d="/usr/local/share/fonts/$1"; shift
    $SU mkdir -p "$d"
    for f in "$@"; do $SU install -m644 "$f" "$d/"; done
    if command -v fc-cache >/dev/null 2>&1; then $SU fc-cache -f "$d" || true; fi
}
VER=2.1.5
fetch "https://github.com/liberationfonts/liberation-fonts/files/7261482/liberation-fonts-ttf-$VER.tar.gz" \
    "liberation-fonts-ttf-$VER.tar.gz" 7191c669bf38899f73a2094ed00f7b800553364f90e2637010a69c0e268f25d0
rm -rf "liberation-fonts-ttf-$VER"
tar xzf "liberation-fonts-ttf-$VER.tar.gz"
cd "liberation-fonts-ttf-$VER"
install_fonts liberation *.ttf
sync
