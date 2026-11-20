SRC="${HDX_SRC:-/hdxp/src/devel-xxhash-src}"
VER=0.8.3
SHA256=aae608dfe8213dfd05d909a57718ef82f30722c392344583d3f39050c7f29a80
TARBALL="xxhash-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/Cyan4973/xxHash/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "xxHash-$VER" ] || tar xf "$TARBALL"
cd "xxHash-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
make clean
make -j"$(nproc)" PREFIX=/usr/local
$SU make install PREFIX=/usr/local
sync
[ -s /usr/local/include/xxhash.h ] && [ -s /usr/local/lib/pkgconfig/libxxhash.pc ]
