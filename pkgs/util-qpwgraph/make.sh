SRC="${HDX_SRC:-/hdxp/src/util-qpwgraph-src}"
PKG="${HDX_PKG:-util-qpwgraph}"
VER=1.0.5
SHA256=823db11212e8587744cb60041a1b7a9cf5bf9b3760aebeb60562b046749d1dfb
TARBALL="qpwgraph-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/rncbc/qpwgraph/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "qpwgraph-$VER" ] || tar xf "$TARBALL"
cd "qpwgraph-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"
command -v cmake >/dev/null || { echo "error: cmake not found (devel-cmake)"; exit 1; }
NINJA=$(command -v ninja || command -v samu || true)
[ -n "$NINJA" ] || { echo "error: neither ninja nor samu found (devel-samurai)"; exit 1; }
[ -s /usr/local/lib/cmake/Qt6/Qt6Config.cmake ] || { echo "error: Qt6 base is not installed (devel-qt6-base)"; exit 1; }
rm -rf build
cmake -S . -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_PREFIX_PATH=/usr/local \
    -DCMAKE_MAKE_PROGRAM="$NINJA" -DCONFIG_QT6=1 -DCONFIG_SYSTEM_TRAY=0
cmake --build build --parallel "$(nproc 2>/dev/null || echo 1)"
$SU cmake --install build
# the install manifest is what uninstall.sh removes, so nothing is guessed on removal
[ -s build/install_manifest.txt ] || { echo "error: no install manifest"; exit 1; }
$SU install -Dm644 build/install_manifest.txt "/usr/local/share/hdxp-manifests/$PKG.txt"
sync
[ -s /usr/local/bin/qpwgraph ]
echo "util-qpwgraph: needs pipewire running; run it with: QT_QPA_PLATFORM=wayland qpwgraph"
