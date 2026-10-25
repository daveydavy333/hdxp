SRC="${HDX_SRC:-/hdxp/src/devel-freetype-src}"
VER=2.15.0
SHA256=9186627467a616d9a9e3e574748ac0c45fa77398e6364edef3041a8ba8d92f64
TARBALL="freetype-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://download.savannah.gnu.org/releases/freetype/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "freetype-$VER" ] || tar xzf "$TARBALL"
cd "freetype-$VER"
CPPFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" ./configure --prefix=/usr/local --disable-static --with-zlib=yes --with-png=yes --with-harfbuzz=no --with-bzip2=no --with-brotli=no
make -j"$(nproc 2>/dev/null || echo 1)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
