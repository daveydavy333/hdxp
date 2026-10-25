SRC="${HDX_SRC:-/hdxp/src/devel-wayland-protocols-src}"
VER=1.49
SHA256=ec4c8f74942d6dff7ace8b4ce4764f0ef9ff618a935d974ea77edee2ad240b14
TARBALL="wayland-protocols-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/$VER/downloads/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "wayland-protocols-$VER" ] || tar xJf "$TARBALL"
cd "wayland-protocols-$VER"
rm -rf build
meson setup build --prefix=/usr/local -Dtests=false
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
