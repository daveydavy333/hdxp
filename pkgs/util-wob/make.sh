SRC="${HDX_SRC:-/hdxp/src/util-wob-src}"
PKG="${HDX_PKG:-util-wob}"
VER=0.16
SHA256=8a5850beec72b5b19be631a6eb21315a20082bf9135447080f9e9045f143938b
TARBALL="wob-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/francma/wob/archive/refs/tags/$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "wob-$VER" ] || tar xf "$TARBALL"
cd "wob-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release -Dseccomp=disabled -Dtests=disabled -Dsystemd-unit-files=disabled -Dman-pages=enabled
meson compile -C build
$SU /usr/local/bin/meson install -C build --no-rebuild
# the install log is what uninstall.sh removes, so nothing is guessed on removal
$SU install -Dm644 build/meson-logs/install-log.txt "/usr/local/share/hdxp-manifests/$PKG.txt"
sync
