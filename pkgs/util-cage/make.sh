SRC="${HDX_SRC:-/hdxp/src/util-cage-src}"
PKG="${HDX_PKG:-util-cage}"
VER=0.3.1
SHA256=6dc1619665acd367e0174c93b234002549a66f55f1de9197d67f0305415babc8
TARBALL="cage-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/cage-kiosk/cage/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "cage-$VER" ] || tar xf "$TARBALL"
cd "cage-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release -Dman-pages=enabled
meson compile -C build
$SU /usr/local/bin/meson install -C build --no-rebuild
# the install log is what uninstall.sh removes, so nothing is guessed on removal
$SU install -Dm644 build/meson-logs/install-log.txt "/usr/local/share/hdxp-manifests/$PKG.txt"
sync
