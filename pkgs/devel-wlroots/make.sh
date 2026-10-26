SRC="${HDX_SRC:-/hdxp/src/devel-wlroots-src}"
VER=0.20.2
SHA256=20c37b521dc3054b6e9627b79bdd45fc716db9ebc58bdf97e57e84d04b04610f
TARBALL="wlroots-$VER.tar.bz2"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/w/wlroots/wlroots_$VER.orig.tar.bz2"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "wlroots-$VER" ] || tar xjf "$TARBALL"
cd "wlroots-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib \
  -Dexamples=false -Dxwayland=disabled -Dcolor-management=disabled \
  -Dlibliftoff=disabled -Dxcb-errors=disabled \
  -Dbackends=drm,libinput -Drenderers=auto -Dallocators=auto
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
