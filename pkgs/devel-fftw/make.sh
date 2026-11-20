# source is the Ubuntu/Debian orig tarball of fftw 3.3.10 (same release as fftw.org, directory fftw3-3.3.10)
SRC="${HDX_SRC:-/hdxp/src/devel-fftw-src}"
VER=3.3.10
SHA256=5499874012aa6ea6c597b8c3807494e271ab2426a889e95d5cc4d154b825e8a0
TARBALL="fftw3_$VER.orig.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "http://archive.ubuntu.com/ubuntu/pool/main/f/fftw3/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "fftw3-$VER" ] || tar xf "$TARBALL"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
rm -rf build
mkdir build
cd build
# -std=gnu17: the old autoconf tests misdetect functions under gcc 15's default C23
EXTRA=""
[ "$(uname -m)" = x86_64 ] && EXTRA="--enable-sse2"
CFLAGS="-O2 -std=gnu17" "../fftw3-$VER/configure" --prefix=/usr/local \
  --enable-shared --enable-static --disable-fortran --disable-doc $EXTRA
make -j"$(nproc)"
$SU make install
sync
[ -s /usr/local/lib/libfftw3.so ] && [ -s /usr/local/include/fftw3.h ]
