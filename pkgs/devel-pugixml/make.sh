SRC="${HDX_SRC:-/hdxp/src/devel-pugixml-src}"
VER=1.16
SHA256=357bcab8877dc9943f355d3a72daba1b053238ba955f50fa81586afb65090219
TARBALL="pugixml-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/p/pugixml/pugixml_1.16.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "pugixml-1.16" ] || tar -xf "$TARBALL"
cd "pugixml-1.16"
rm -rf build
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON -DPUGIXML_BUILD_TESTS=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
