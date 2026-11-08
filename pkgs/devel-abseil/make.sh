SRC="${HDX_SRC:-/hdxp/src/devel-abseil-src}"
TAG=20260526.0
COMMIT=5650e9cf76d3be4318d5fa3af38ee483ddfd5e4a
mkdir -p "$SRC"
cd "$SRC"
[ -d abseil-cpp ] || git clone https://github.com/abseil/abseil-cpp
cd abseil-cpp
git fetch --tags
git checkout "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "commit mismatch"; exit 1; }
rm -rf build
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=17 -DBUILD_SHARED_LIBS=ON -DABSL_PROPAGATE_CXX_STD=ON \
  -DABSL_BUILD_TESTING=OFF -DABSL_ENABLE_INSTALL=ON -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
