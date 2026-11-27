VER=12.2.1
SHA=449374d74f31b67796dece454d59b93e6f1538efcce0e9ac78000c98142c139e
TAR="fmt-$VER.tar.gz"
SRC="${HDX_SRC:-/hdxp/src/devel-fmt-src}"
PKG="${HDX_PKG:-devel-fmt}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"
command -v cmake >/dev/null || { echo "error: cmake not found (devel-cmake)"; exit 1; }
JOBS=$(nproc 2>/dev/null || echo 1)

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://github.com/fmtlib/fmt/archive/refs/tags/12.2.1.tar.gz"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "fmt-$VER" ] || tar -xf "$TAR"
cd "fmt-$VER"

rm -rf build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_SHARED_LIBS=ON -DFMT_TEST=OFF -DFMT_DOC=OFF -DFMT_INSTALL=ON
cmake --build build --parallel "$JOBS"
$SU cmake --install build
[ -s build/install_manifest.txt ] || { echo "error: no install manifest"; exit 1; }
$SU install -Dm644 build/install_manifest.txt "/usr/local/share/hdxp-manifests/$PKG.txt"
sync

for f in lib/libfmt.so lib/cmake/fmt/fmt-config.cmake; do
    [ -s "/usr/local/$f" ] || { echo "error: /usr/local/$f is empty or missing"; exit 1; }
done
