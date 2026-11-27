VER=1.2.1
SHA=98d35d11a78dc453aebb7d10c3748f3f73ff78c8267c0dc697b8631f67bf7e8f
TAR="brotli-$VER.tar.gz"
SRC="${HDX_SRC:-/hdxp/src/devel-brotli-src}"
PKG="${HDX_PKG:-devel-brotli}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"
command -v cmake >/dev/null || { echo "error: cmake not found (devel-cmake)"; exit 1; }
JOBS=$(nproc 2>/dev/null || echo 1)

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://github.com/google/brotli/archive/refs/tags/v1.2.1.tar.gz"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "brotli-$VER" ] || tar -xf "$TAR"
cd "brotli-$VER"

rm -rf build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_SHARED_LIBS=ON -DBROTLI_BUILD_TOOLS=ON -DBROTLI_DISABLE_TESTS=ON
cmake --build build --parallel "$JOBS"
$SU cmake --install build
[ -s build/install_manifest.txt ] || { echo "error: no install manifest"; exit 1; }
$SU install -Dm644 build/install_manifest.txt "/usr/local/share/hdxp-manifests/$PKG.txt"
sync

for f in bin/brotli lib/libbrotlicommon.so lib/libbrotlidec.so lib/libbrotlienc.so lib/pkgconfig/libbrotlidec.pc; do
    [ -s "/usr/local/$f" ] || { echo "error: /usr/local/$f is empty or missing"; exit 1; }
done
