SRC="${HDX_SRC:-/hdxp/src/devel-libmagic-src}"
VER=5.47
SHA256=45672fec165cb4cc1358a2d76b5d57d22876dcb97ab169427ac385cbe1d5597a
TARBALL="file-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/f/file/file_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "file-$VER" ] || tar -xf "$TARBALL"
cd "file-$VER"
./configure --prefix=/usr/local --libdir=/usr/local/lib --disable-static \
  --disable-zlib --disable-bzlib --disable-xzlib --disable-zstdlib --disable-lzlib --disable-libseccomp
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
