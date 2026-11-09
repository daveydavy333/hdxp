SRC="${HDX_SRC:-/hdxp/src/devel-libzip-src}"
TAG=v1.12.1
COMMIT=8e037534ccd62f444abbe4ce265443ee74bbfeb3
mkdir -p "$SRC"
cd "$SRC"
[ -d libzip ] || git clone https://github.com/nih-at/libzip
cd libzip
git fetch --tags
git checkout "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "commit mismatch"; exit 1; }
rm -rf build
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON -DBUILD_TOOLS=OFF -DBUILD_REGRESS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_DOC=OFF \
  -DENABLE_BZIP2=OFF -DENABLE_LZMA=OFF -DENABLE_ZSTD=OFF -DENABLE_OPENSSL=OFF -DENABLE_GNUTLS=OFF \
  -DENABLE_COMMONCRYPTO=OFF -DENABLE_WINDOWS_CRYPTO=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
