SRC="${HDX_SRC:-/hdxp/src/devel-libxkbcommon-src}"
VER=1.13.1
SHA256=aeb951964c2f7ecc08174cb5517962d157595e9e3f38fc4a130b91dc2f9fec18
TARBALL="libxkbcommon-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/xkbcommon/libxkbcommon/archive/refs/tags/xkbcommon-$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "libxkbcommon-xkbcommon-$VER" ] || tar xzf "$TARBALL"
cd "libxkbcommon-xkbcommon-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib \
  -Denable-docs=false -Denable-x11=false -Denable-wayland=false \
  -Denable-xkbregistry=false -Denable-tools=false \
  -Dxkb-config-root=/usr/local/share/X11/xkb
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
