SRC="${HDX_SRC:-/hdxp/src/devel-lcms2-src}"
VER=2.19.1
SHA256=bfc54f7bab59fbc921012014a8032e4cba4abd46db47d46b76416a8c0b2815c8
TARBALL="lcms2-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/l/lcms2/lcms2_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "lcms2-$VER" ] || tar -xf "$TARBALL"
cd "lcms2-$VER"
./configure --prefix=/usr/local --libdir=/usr/local/lib --disable-static
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
