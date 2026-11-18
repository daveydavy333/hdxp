#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-misc-noto-fonts}"
SRC="${HDX_SRC:-/hdxp/src/misc-noto-fonts-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() { # need <pkg-config module> <min version>
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "misc-noto-fonts: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
# fetch <url> <file> <sha256>; an empty sha means "unpinned": print it and stop,
# unless HDX_TOFU=1 (then trust this first download)
fetch() {
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    if [ -z "$3" ]; then
        echo "misc-noto-fonts: UNPINNED $2 sha256=$(sha256sum "$2" | cut -d' ' -f1)" >&2
        [ "${HDX_TOFU:-0}" = 1 ] || { echo "misc-noto-fonts: re-run with HDX_TOFU=1 to accept, then pin this sha in make.sh" >&2; exit 1; }
        return 0
    fi
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "misc-noto-fonts: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}
mkdir -p "$SRC"
cd "$SRC"

install_fonts() { # install_fonts <dir> <files...>
    d="/usr/local/share/fonts/$1"; shift
    $SU mkdir -p "$d"
    for f in "$@"; do $SU install -m644 "$f" "$d/"; done
    if command -v fc-cache >/dev/null 2>&1; then $SU fc-cache -f "$d" || true; fi
}
REV=15f23a0fd72c87285f50e890af8cf64d82d588a3
BASE="https://raw.githubusercontent.com/notofonts/notofonts.github.io/$REV/fonts"
mkdir -p noto && cd noto
get() { fetch "$BASE/$1/hinted/ttf/$2.ttf" "$2.ttf" "$3"; }
get NotoSans NotoSans-Regular 478c558ea716033cd60c03438f628dfa75694dcf6b5f6d505a2f05fd2b4f3823
get NotoSans NotoSans-Bold 1df075a380fc7cb898acf64c1f7b3b4dd780de3caa860178bf929de35817a913
get NotoSans NotoSans-Italic 467e3f89eeca4108bb8710a2b9e0cf2281ac56d5b0609211a83776d0505eecb5
get NotoSans NotoSans-BoldItalic 1b602a9d6353be42c91df097a4857b69fa2696f26703d7a33b54a15d87c2622c
get NotoSerif NotoSerif-Regular 19e72cd8d595fae5bd74a5206f5d938512e1183d4fed7abb1ec1be1d7efa5f88
get NotoSerif NotoSerif-Bold 96656aa5cec8f1d6fd0e804c1fad397e1a1cfa082e6642124e0bda68cd8363ce
get NotoSerif NotoSerif-Italic 749e80e313ef711f9373c6cce17c72297ef05490b3dcda7967d1d5d90bf1183f
get NotoSansMono NotoSansMono-Regular 65b5e2b2c4a1fba9ae8be1f026cb35b03dcb8886d9b2a4147054fde12f7e767d
get NotoSansMono NotoSansMono-Bold a21ea0ba6ea49fda7b34ca39a504b487f1130885d36e1a4f9f4255b3ba6994bc
install_fonts noto *.ttf
sync
