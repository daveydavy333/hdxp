SRC="${HDX_SRC:-/hdxp/src/devel-libwebp-src}"
VER=1.6.0
SHA256=e4ab7009bf0629fd11982d4c2aa83964cf244cffba7347ecd39019a9e38c4564
TARBALL="libwebp-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/libw/libwebp/libwebp_1.6.0.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "libwebp-1.6.0" ] || tar -xf "$TARBALL"
cd "libwebp-1.6.0"
rm -rf build
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON -DWEBP_BUILD_ANIM_UTILS=OFF -DWEBP_BUILD_CWEBP=OFF -DWEBP_BUILD_DWEBP=OFF -DWEBP_BUILD_GIF2WEBP=OFF -DWEBP_BUILD_IMG2WEBP=OFF -DWEBP_BUILD_VWEBP=OFF -DWEBP_BUILD_WEBPINFO=OFF -DWEBP_BUILD_WEBPMUX=OFF -DWEBP_BUILD_EXTRAS=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
