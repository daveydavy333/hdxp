#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-devel-libusb}"
SRC="${HDX_SRC:-/hdxp/src/devel-libusb-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() { # need <pkg-config module> <min version>
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "devel-libusb: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
# fetch <url> <file> <sha256>; an empty sha means "unpinned": print it and stop,
# unless HDX_TOFU=1 (then trust this first download)
fetch() {
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    if [ -z "$3" ]; then
        echo "devel-libusb: UNPINNED $2 sha256=$(sha256sum "$2" | cut -d' ' -f1)" >&2
        [ "${HDX_TOFU:-0}" = 1 ] || { echo "devel-libusb: re-run with HDX_TOFU=1 to accept, then pin this sha in make.sh" >&2; exit 1; }
        return 0
    fi
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "devel-libusb: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}
mkdir -p "$SRC"
cd "$SRC"

VER=1.0.30
fetch "https://github.com/libusb/libusb/releases/download/v$VER/libusb-$VER.tar.bz2" \
    "libusb-$VER.tar.bz2" fea36f34f9156400209595e300840767ab1a385ede1dc7ee893015aea9c6dbaf
rm -rf "libusb-$VER"
tar xf "libusb-$VER.tar.bz2"
cd "libusb-$VER"
# --disable-udev: hotplug via netlink, no libudev needed
./configure --prefix=/usr/local --disable-udev --disable-static
make -j "$JOBS"
$SU make install
sync
