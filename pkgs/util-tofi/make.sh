SRC="${HDX_SRC:-/hdxp/src/util-tofi-src}"
PKG="${HDX_PKG:-util-tofi}"
VER=0.9.1
SHA256=dd55347b509af786f133def64f3a86f1db258b5e196de80e53d62827bdcc37bc
TARBALL="tofi-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/philj56/tofi/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "tofi-$VER" ] || tar xf "$TARBALL"
cd "tofi-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release -Dman-pages=enabled
meson compile -C build
$SU /usr/local/bin/meson install -C build --no-rebuild
# the install log is what uninstall.sh removes, so nothing is guessed on removal
$SU install -Dm644 build/meson-logs/install-log.txt "/usr/local/share/hdxp-manifests/$PKG.txt"
sync
