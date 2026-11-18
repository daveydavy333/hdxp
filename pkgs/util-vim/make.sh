#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-util-vim}"
SRC="${HDX_SRC:-/hdxp/src/util-vim-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() { # need <pkg-config module> <min version>
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "util-vim: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
# fetch <url> <file> <sha256>; an empty sha means "unpinned": print it and stop,
# unless HDX_TOFU=1 (then trust this first download)
fetch() {
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    if [ -z "$3" ]; then
        echo "util-vim: UNPINNED $2 sha256=$(sha256sum "$2" | cut -d' ' -f1)" >&2
        [ "${HDX_TOFU:-0}" = 1 ] || { echo "util-vim: re-run with HDX_TOFU=1 to accept, then pin this sha in make.sh" >&2; exit 1; }
        return 0
    fi
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "util-vim: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}
mkdir -p "$SRC"
cd "$SRC"

VER=9.2.1364
fetch "https://github.com/vim/vim/archive/refs/tags/v$VER.tar.gz" \
    "vim-$VER.tar.gz" 64dd84cbe15244f45063ce0c923eb5a25252273484afaea7a71353e2add777e3
rm -rf "vim-$VER"
tar xzf "vim-$VER.tar.gz"
cd "vim-$VER"
./configure --prefix=/usr/local --with-features=normal --with-tlib=ncurses \
    --disable-gui --without-x --disable-nls --disable-gpm --disable-sysmouse \
    --disable-canberra --enable-multibyte
make -j "$JOBS"
$SU make install
[ -e /usr/local/bin/vi ] || $SU ln -s vim /usr/local/bin/vi
sync
