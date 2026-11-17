#!/bin/sh
# util-hevel: hevel, scrollable floating wayland window manager driven by mouse chords (neuswc)
set -eu

NAME=util-hevel
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-$NAME}"
SRC="${HDX_SRC:-/hdxp/src/$NAME-src}"
PREFIX=/usr/local
URL=https://git.sr.ht/~dlm/hevel
COMMIT="7ef61a5c0d4012417443734919ac723635cd5464"

if [ "$(id -u)" -eq 0 ]; then SU=; else SU=doas; fi

[ "$COMMIT" != FILLME ] || { echo "$NAME: COMMIT is not pinned yet (run pin.sh)" >&2; exit 1; }

[ -d "$SRC/.git" ] || git clone -q "$URL" "$SRC"
cd "$SRC"
git fetch -q origin "$COMMIT" 2>/dev/null || git fetch -q origin
git checkout -q -f "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "$NAME: commit mismatch" >&2; exit 1; }

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

# config.h: your own /etc/hdxi/hevel-config.h wins, else keep an existing one,
# else take the default and adapt it to foot
if [ -f /etc/hdxi/hevel-config.h ]; then
    cp /etc/hdxi/hevel-config.h config.h
elif [ ! -f config.h ]; then
    cp config.def.h config.h
    # foot takes the app-id with -a (its -w is window-size-pixels), and hevel
    # waits for a window with exactly that app-id, so pass -a and list it
    sed -i 's/term_flag = "-w"/term_flag = "-a"/' config.h
    sed -i 's/terminal_app_ids\[\] = {"foot", /terminal_app_ids[] = {"foot", "foot-256color", /' config.h
fi

make clean >/dev/null 2>&1 || true
make \
    CC="${CC:-cc}" \
    CFLAGS="-std=c99 -O2 -D_GNU_SOURCE $(pkg-config --cflags swc wld)" \
    LDFLAGS="-Wl,-rpath,$PREFIX/lib" \
    LDLIBS="$(pkg-config --libs swc wld)" \
    hevel

$SU install -D -m 755 hevel "$PREFIX/bin/hevel"
$SU install -D -m 755 "$PORT/hevel-start" "$PREFIX/bin/hevel-start"
echo "$NAME installed"
