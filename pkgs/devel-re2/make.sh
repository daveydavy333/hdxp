SRC="${HDX_SRC:-/hdxp/src/devel-re2-src}"
TAG=2025-11-05
COMMIT=927f5d53caf8111721e734cf24724686bb745f55
mkdir -p "$SRC"
cd "$SRC"
[ -d re2 ] || git clone https://github.com/google/re2
cd re2
git fetch --tags
git checkout "$COMMIT"
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "commit mismatch"; exit 1; }
rm -rf build
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=17 -DBUILD_SHARED_LIBS=ON -DRE2_BUILD_TESTING=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
