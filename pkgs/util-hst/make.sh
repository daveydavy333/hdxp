#!/bin/sh
# util-hst: hst, st-wl fork for neuswc compositors with neuwld font rendering (installs as st-wl)
set -eu

NAME=util-hst
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-$NAME}"
SRC="${HDX_SRC:-/hdxp/src/$NAME-src}"
PREFIX=/usr/local
URL=https://git.sr.ht/~dlm/hst
COMMIT="5906386421930127f450c3450a4600536e4cd5c6"
JOBS="${HDX_JOBS:-$(nproc)}"

if [ "$(id -u)" -eq 0 ]; then SU=; else SU=doas; fi

[ "$COMMIT" != FILLME ] || { echo "$NAME: COMMIT is not pinned yet (run pin.sh)" >&2; exit 1; }

[ -d "$SRC/.git" ] || git clone -q "$URL" "$SRC"
cd "$SRC"
git fetch -q origin "$COMMIT" 2>/dev/null || git fetch -q origin
git checkout -q -f "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "$NAME: commit mismatch" >&2; exit 1; }

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

# font: the default asks for a nerd font; HDXI ships DejaVu (misc-dejavu-fonts).
# Only touched when config.h doesn't exist yet; keep your own via /etc/hdxi/hst-config.h
if [ -f /etc/hdxi/hst-config.h ]; then
    cp /etc/hdxi/hst-config.h config.h
elif [ ! -f config.h ]; then
    cp config.def.h config.h
    sed -i 's/^static char \*font = .*/static char *font = "DejaVu Sans Mono:pixelsize=14:antialias=true:autohint=true";/' config.h
fi

make clean >/dev/null 2>&1 || true
make CC="${CC:-cc}" -j "$JOBS"

$SU install -D -m 755 st-wl "$PREFIX/bin/st-wl"
# terminfo for TERM=st-256color (best effort, needs tic from the ncurses port)
if [ -f st.info ] && command -v tic >/dev/null 2>&1; then
    $SU tic -sx st.info || echo "$NAME: tic failed, terminfo not installed" >&2
fi
echo "$NAME installed"
