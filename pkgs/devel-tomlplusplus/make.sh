SRC="${HDX_SRC:-/hdxp/src/devel-tomlplusplus-src}"
VER=3.4.0
SHA256=0ae736e13a49cc8a0aa7799705cf18bd93f5f56624613e6aa554b65fe2d72768
TARBALL="tomlplusplus-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/t/tomlplusplus/tomlplusplus_$VER+ds.orig.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d marzer-tomlplusplus-3017243 ] || tar -xf "$TARBALL"
cd marzer-tomlplusplus-3017243
rm -rf build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
meson setup build --prefix=/usr/local --buildtype=release
meson compile -C build
$SU meson install -C build
