SRC="${HDX_SRC:-/hdxp/src/devel-cmake-src}"
VER=4.4.5
SHA256=a0c54c88abb8078dd8eccadb717fc6bb194bf18e7d44c86309910288886e04e2
TARBALL="cmake-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/Kitware/CMake/releases/download/v$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "cmake-$VER" ] || tar xf "$TARBALL"
cd "cmake-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
JOBS="${HDX_JOBS:-$(nproc 2>/dev/null || echo 1)}"
./bootstrap --prefix=/usr/local --parallel="$JOBS" -- -DCMAKE_USE_OPENSSL=OFF -DBUILD_TESTING=OFF -DBUILD_CursesDialog=OFF
make -j"$JOBS"
$SU make install
