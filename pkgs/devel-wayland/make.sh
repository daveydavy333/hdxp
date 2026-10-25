SRC="${HDX_SRC:-/hdxp/src/devel-wayland-src}"
VER=1.26.0
SHA256=64176eaa46e4969903e286f8e5ef8331affc17fdf03ac9b58381d2b23162b7a3
TARBALL="wayland-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://gitlab.freedesktop.org/wayland/wayland/-/releases/$VER/downloads/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "wayland-$VER" ] || tar xJf "$TARBALL"
cd "wayland-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib -Ddocumentation=false -Dtests=false -Ddtd_validation=false
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
