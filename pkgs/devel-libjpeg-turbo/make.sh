SRC="${HDX_SRC:-/hdxp/src/devel-libjpeg-turbo-src}"
VER=3.1.3
SHA256=3a13a5ba767dc8264bc40b185e41368a80d5d5f945944d1dbaa4b2fb0099f4e5
TARBALL="libjpeg-turbo-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/libj/libjpeg-turbo/libjpeg-turbo_3.1.3.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "libjpeg-turbo-3.1.3" ] || tar -xf "$TARBALL"
cd "libjpeg-turbo-3.1.3"
rm -rf build
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_STATIC=OFF -DWITH_SIMD=OFF -DWITH_TOOLS=OFF -DWITH_JAVA=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
