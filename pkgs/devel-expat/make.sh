SRC="${HDX_SRC:-/hdxp/src/devel-expat-src}"
VER=2.9.0
TAG=R_2_9_0
SHA256=16afbb9cefead2aa278105cf27d9f597bde7fbf3dbb85015857ca7ca6a4e89ba
TARBALL="expat-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/libexpat/libexpat/releases/download/$TAG/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "expat-$VER" ] || tar xzf "$TARBALL"
cd "expat-$VER"
./configure --prefix=/usr/local --disable-static --without-docbook --without-examples --without-tests
make -j"$(nproc 2>/dev/null || echo 1)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
