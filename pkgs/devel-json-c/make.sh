SRC="${HDX_SRC:-/hdxp/src/devel-json-c-src}"
VER=0.17
SHA256=024d302a3aadcbf9f78735320a6d5aedf8b77876c8ac8bbb95081ca55054c7eb
TARBALL="json-c-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/j/json-c/json-c_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "json-c-json-c-$VER-20230812" ] || tar -xf "$TARBALL"
cd "json-c-json-c-$VER-20230812"
rm -rf build
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_STATIC_LIBS=OFF -DBUILD_APPS=OFF -DDISABLE_WERROR=ON -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
