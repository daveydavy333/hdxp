SRC="${HDX_SRC:-/hdxp/src/devel-muparser-src}"
VER=2.3.4
SHA256=b9aca98eabeb34458d272ff8f2dd3df7fbd61b4b612c49eb6dcc9468109aac88
TARBALL="muparser-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/m/muparser/muparser_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d beltoforion-muparser-59e0ce1 ] || tar -xf "$TARBALL"
cd beltoforion-muparser-59e0ce1
rm -rf build
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON -DENABLE_SAMPLES=OFF -DENABLE_OPENMP=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
