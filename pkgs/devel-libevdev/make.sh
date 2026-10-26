SRC="${HDX_SRC:-/hdxp/src/devel-libevdev-src}"
VER=1.13.6
SHA256=6643222f13cfbead0e30b8b74600f6d335f6ebb1ad8cbaf85783e36886689071
TARBALL="libevdev-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/libe/libevdev/libevdev_$VER+dfsg.orig.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "libevdev-$VER" ] || tar xJf "$TARBALL"
cd "libevdev-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib -Dtests=disabled -Ddocumentation=disabled
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
