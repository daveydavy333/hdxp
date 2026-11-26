VER=6.12.1
SHA=6378c7427d618f61c2ee2f6f848bf65f0ff38cb5319de6ed86eb35566c7baa9e
MOD=qtdeclarative
TAR="$MOD-$VER.tar.gz"
SRC="${HDX_SRC:-/hdxp/src/skp-devel-qt6-declarative-src}"
PKG="${HDX_PKG:-skp-devel-qt6-declarative}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"
command -v cmake >/dev/null || { echo "error: cmake not found (devel-cmake)"; exit 1; }
NINJA=$(command -v ninja || command -v samu || true)
[ -n "$NINJA" ] || { echo "error: neither ninja nor samu found (devel-samurai)"; exit 1; }

[ -s /usr/local/lib/cmake/Qt6/Qt6Config.cmake ] || { echo "error: Qt6 base is not installed (skp/devel-qt6-base)"; exit 1; }

# qt links eat memory: allow about 1.5 GB per parallel job
JOBS=$(nproc 2>/dev/null || echo 1)
MEM=$(awk '/^MemTotal:/ {print int($2 / 1048576)}' /proc/meminfo 2>/dev/null || echo 4)
MAXJ=$((MEM * 2 / 3))
[ "$MAXJ" -ge 1 ] || MAXJ=1
[ "$JOBS" -le "$MAXJ" ] || JOBS=$MAXJ
echo "building with $JOBS parallel jobs"

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://github.com/qt/$MOD/archive/refs/tags/v$VER.tar.gz"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "$MOD-$VER" ] || tar -xf "$TAR"
cd "$MOD-$VER"

if [ ! -f build/build.ninja ]; then
    rm -rf build
    cmake -S . -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_PREFIX_PATH=/usr/local \
        -DCMAKE_MAKE_PROGRAM="$NINJA" \
        -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DQT_BUILD_BENCHMARKS=OFF -DBUILD_TESTING=OFF 
fi

cmake --build build --parallel "$JOBS"
$SU cmake --install build

# the install manifest is what uninstall.sh removes, so nothing is guessed on removal
[ -s build/install_manifest.txt ] || { echo "error: no install manifest"; exit 1; }
$SU install -Dm644 build/install_manifest.txt "/usr/local/share/hdxp-manifests/$PKG.txt"

QB=/usr/local/lib/qt6/bin
for pair in qml:qml qmlformat:qmlformat qmllint:qmllint; do
    src=${pair%%:*}
    dst=${pair##*:}
    if [ -x "$QB/$src" ]; then $SU ln -sf "$QB/$src" "/usr/local/bin/$dst"; fi
done
sync

for f in lib/libQt6Qml.so lib/libQt6Quick.so; do
    [ -s "/usr/local/$f" ] || { echo "error: /usr/local/$f is empty or missing"; exit 1; }
done
echo "note: no OpenGL here, so run Qt Quick programs with QT_QUICK_BACKEND=software"
