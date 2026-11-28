SRC="${HDX_SRC:-/hdxp/src/util-swayidle-src}"
PKG="${HDX_PKG:-util-swayidle}"
VER=1.9.1
SHA256=846372a151e9f65bbc50e86d600fc7d7f9e494c3e2fcbc23b4d1ead9a13bcd1e
TARBALL="swayidle-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/swaywm/swayidle/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "swayidle-$VER" ] || tar xf "$TARBALL"
cd "swayidle-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release -Dlogind=disabled -Dman-pages=enabled -Dzsh-completions=false -Dbash-completions=false -Dfish-completions=false
meson compile -C build
$SU /usr/local/bin/meson install -C build --no-rebuild
# the install log is what uninstall.sh removes, so nothing is guessed on removal
$SU install -Dm644 build/meson-logs/install-log.txt "/usr/local/share/hdxp-manifests/$PKG.txt"
sync
