#!/bin/sh
# devel-libcap: libcap 2.77 (POSIX capabilities), required by OpenRC on Linux
set -eu
NAME=devel-libcap
VER=2.77
SHA=897bc18b44afc26c70e78cead3dbb31e154acc24bee085a5a09079a88dbf6f52
URL="https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-$VER.tar.xz"
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-$NAME}"
SRC="${HDX_SRC:-/hdxp/src/$NAME-src}"
[ "$(id -u)" = 0 ] && SU= || SU=doas

mkdir -p "$SRC"; cd "$SRC"
[ -f "libcap-$VER.tar.xz" ] || curl -fL -o "libcap-$VER.tar.xz" "$URL"
echo "$SHA  libcap-$VER.tar.xz" | sha256sum -c -
rm -rf "libcap-$VER"; tar xf "libcap-$VER.tar.xz"; cd "libcap-$VER"

OPTS="prefix=/usr/local lib=lib RAISE_SETFCAP=no PAM_CAP=no GOLANG=no BUILD_CC=${CC:-cc}"
make -j1 $OPTS
$SU make $OPTS install
sync
echo "devel-libcap $VER installed (pkg-config: libcap, libpsx in /usr/local/lib/pkgconfig)"
