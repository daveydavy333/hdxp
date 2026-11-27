VER=36.2
SHA=7e7eaf580ec77f1a392ff1ab1013c13d3b04a6716f002f697f67f3c1113f0530
TAR="protobuf-$VER.tar.gz"
SRC="${HDX_SRC:-/hdxp/src/devel-protobuf-src}"
PKG="${HDX_PKG:-devel-protobuf}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"
command -v cmake >/dev/null || { echo "error: cmake not found (devel-cmake)"; exit 1; }
JOBS=$(nproc 2>/dev/null || echo 1)

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://github.com/protocolbuffers/protobuf/archive/refs/tags/v36.2.tar.gz"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "protobuf-$VER" ] || tar -xf "$TAR"
cd "protobuf-$VER"

# needs abseil >= 20250512.1 from devel-abseil (never downloaded: protobuf_LOCAL_DEPENDENCIES_ONLY)
for f in /usr/local/lib/pkgconfig/absl_base.pc; do
    [ -f "$f" ] && grep '^Version:' "$f" | sed 's/^/abseil /' || echo "note: no absl_base.pc, relying on cmake to find abseil"
done

# a failed build is resumed, not restarted: rm -rf build to force a reconfigure
if [ ! -f build/CMakeCache.txt ]; then
    rm -rf build
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_CXX_STANDARD=17 \
        -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_SHARED_LIBS=OFF -Dprotobuf_WITH_ZLIB=OFF \
        -Dprotobuf_LOCAL_DEPENDENCIES_ONLY=ON -Dprotobuf_INSTALL=ON
fi
cmake --build build --parallel "$JOBS"
$SU cmake --install build
[ -s build/install_manifest.txt ] || { echo "error: no install manifest"; exit 1; }
$SU install -Dm644 build/install_manifest.txt "/usr/local/share/hdxp-manifests/$PKG.txt"
sync

for f in bin/protoc lib/libprotobuf.a lib/cmake/protobuf/protobuf-config.cmake; do
    [ -s "/usr/local/$f" ] || { echo "error: /usr/local/$f is empty or missing"; exit 1; }
done
