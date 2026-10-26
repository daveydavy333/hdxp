SRC="${HDX_SRC:-/hdxp/src/misc-hwdata-src}"
VER=0.412
SHA256=f0c64cd7e31d70a5fb3a52e53ab50a61e74c0421a6381eaa45114eec3bde5fe7
TARBALL="hwdata-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/vcrhonek/hwdata/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "hwdata-$VER" ] || tar xzf "$TARBALL"
cd "hwdata-$VER"
./configure --prefix=/usr/local --disable-blacklist
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
