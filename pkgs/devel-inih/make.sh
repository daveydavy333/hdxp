SRC="${HDX_SRC:-/hdxp/src/devel-inih-src}"
PKG="${HDX_PKG:-devel-inih}"
VER=r63
SHA256=5d7967de62c5bfdc4f9f5ab06ce44c9e498bae021c7dac5792c0696e76aa9963
TARBALL="inih-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/benhoyt/inih/archive/refs/tags/$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "inih-$VER" ] || tar xf "$TARBALL"
cd "inih-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release -Ddistro_install=true -Dwith_INIReader=false -Dtests=false
meson compile -C build
$SU /usr/local/bin/meson install -C build --no-rebuild
# the install log is what uninstall.sh removes, so nothing is guessed on removal
$SU install -Dm644 build/meson-logs/install-log.txt "/usr/local/share/hdxp-manifests/$PKG.txt"
sync
