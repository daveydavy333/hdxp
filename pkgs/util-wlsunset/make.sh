SRC="${HDX_SRC:-/hdxp/src/util-wlsunset-src}"
PKG="${HDX_PKG:-util-wlsunset}"
VER=0.3.0
SHA256=b834c520744784346196ec9bdd055a14172edcbf3cd8bb72e53e206d0d41f929
TARBALL="wlsunset_$VER.orig.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/w/wlsunset/wlsunset_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "wlsunset-$VER" ] || tar xf "$TARBALL"
cd "wlsunset-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release -Dman-pages=enabled
meson compile -C build
$SU /usr/local/bin/meson install -C build --no-rebuild
# the install log is what uninstall.sh removes, so nothing is guessed on removal
$SU install -Dm644 build/meson-logs/install-log.txt "/usr/local/share/hdxp-manifests/$PKG.txt"
sync
