#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-util-usbutils}"
SRC="${HDX_SRC:-/hdxp/src/util-usbutils-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() { # need <pkg-config module> <min version>
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "util-usbutils: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
# fetch <url> <file> <sha256>; an empty sha means "unpinned": print it and stop,
# unless HDX_TOFU=1 (then trust this first download)
fetch() {
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    if [ -z "$3" ]; then
        echo "util-usbutils: UNPINNED $2 sha256=$(sha256sum "$2" | cut -d' ' -f1)" >&2
        [ "${HDX_TOFU:-0}" = 1 ] || { echo "util-usbutils: re-run with HDX_TOFU=1 to accept, then pin this sha in make.sh" >&2; exit 1; }
        return 0
    fi
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "util-usbutils: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}
mkdir -p "$SRC"
cd "$SRC"

VER=020
fetch "https://github.com/gregkh/usbutils/archive/refs/tags/v$VER.tar.gz" \
    "usbutils-$VER.tar.gz" ec21bd8fe8d2ce60664acd6a5dab058d18de98b9b4545105fbe90b2a3c4fa604

need libusb-1.0 1.0.22
# usbutils names devices through udev's hwdb: libudev-zero has no hwdb, eudev does
LIBDIR=$(pkg-config --variable=libdir libudev 2>/dev/null || true)
if [ -z "$LIBDIR" ] || ! grep -aq udev_hwdb_new "$LIBDIR"/libudev.so* 2>/dev/null; then
    echo "util-usbutils: libudev here has no hwdb support (libudev-zero?). Install sys-eudev's libudev first." >&2
    exit 1
fi

rm -rf "usbutils-$VER"
tar xzf "usbutils-$VER.tar.gz"
cd "usbutils-$VER"
# eudev's version number is not udev's: drop the >= 196 check
sed -i "s/dependency('libudev', version: '>= 196')/dependency('libudev')/" meson.build
grep -q "dependency('libudev')" meson.build || { echo "util-usbutils: libudev patch did not apply" >&2; exit 1; }
meson setup build --prefix=/usr/local --buildtype=release --wrap-mode=nofallback
meson compile -C build -j "$JOBS"
$SU env DESTDIR= meson install -C build
sync
