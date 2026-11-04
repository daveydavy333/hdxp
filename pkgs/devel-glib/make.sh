SRC="${HDX_SRC:-/hdxp/src/devel-glib-src}"
VER=2.88.0
SHA256=3546251ccbb3744d4bc4eb48354540e1f6200846572bab68e3a2b7b2b64dfd07
TARBALL="glib-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/g/glib2.0/glib2.0_$VER.orig.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "glib-$VER" ] || tar -xf "$TARBALL"
cd "glib-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release --wrap-mode=nofallback \
  -Dtests=false -Dintrospection=disabled -Dnls=disabled -Dlibmount=disabled -Dselinux=disabled \
  -Dxattr=false -Dsysprof=disabled -Dman-pages=disabled -Ddocumentation=false -Dlibelf=disabled \
  -Ddtrace=disabled -Dsystemtap=disabled
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
