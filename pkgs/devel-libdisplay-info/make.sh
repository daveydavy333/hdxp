SRC="${HDX_SRC:-/hdxp/src/devel-libdisplay-info-src}"
VER=0.3.0
SHA256=915cc6713b7b2e173a90f9db248fb8994f9668171fecc1e9fded5e36bb34d890
TARBALL="libdisplay-info-$VER.tar.bz2"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/libd/libdisplay-info/libdisplay-info_$VER.orig.tar.bz2"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "libdisplay-info-$VER" ] || tar xjf "$TARBALL"
cd "libdisplay-info-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
