#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-util-labwc}"
SRC="${HDX_SRC:-/hdxp/src/util-labwc-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() { # need <pkg-config module> <min version>
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "util-labwc: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
fetch() { # fetch <url> <file> <sha256>
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "util-labwc: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}
mkdir -p "$SRC"
cd "$SRC"
VER=0.20.3
fetch "https://github.com/labwc/labwc/archive/refs/tags/$VER.tar.gz" \
    "labwc-$VER.tar.gz" 1e70a5b74f149c5b47da76063dbdf967c44b2d7b6e94d3fdf65f70fc252f65c9

need wlroots-0.20 0.20.1
need wayland-server 1.22.90
need wayland-protocols 1.39
need libinput 1.26
need xkbcommon 0
need libdrm 0
need libxml-2.0 0
need glib-2.0 0
need pangocairo 0
need pixman-1 0
need libpng 0
need librsvg-2.0 2.46

rm -rf "labwc-$VER"
tar xzf "labwc-$VER.tar.gz"
cd "labwc-$VER"

# xwayland off (no xcb stack), nls off (musl), icon off (needs libsfdo, not ported)
# --wrap-mode=nofallback: never let meson download wlroots/libsfdo
meson setup build \
    --prefix=/usr/local --sysconfdir=/etc --libdir=lib \
    --buildtype=release --wrap-mode=nofallback \
    -Dxwayland=disabled -Dnls=disabled -Dicon=disabled \
    -Dsystemd-session=disabled -Dtest=disabled
meson compile -C build -j "$JOBS"
$SU env DESTDIR= meson install -C build
sync
