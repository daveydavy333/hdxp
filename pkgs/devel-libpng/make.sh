SRC="${HDX_SRC:-/hdxp/src/devel-libpng-src}"
VER=1.6.59
SHA256=2540302a1844ad2b2b501977abecfa850f265f97b78f065a712ab4074a89f5b5
TARBALL="libpng-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/pnggroup/libpng/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "libpng-$VER" ] || tar xzf "$TARBALL"
cd "libpng-$VER"
CPPFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" ./configure --prefix=/usr/local --disable-static
make -j"$(nproc 2>/dev/null || echo 1)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
