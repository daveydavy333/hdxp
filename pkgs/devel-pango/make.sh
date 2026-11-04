SRC="${HDX_SRC:-/hdxp/src/devel-pango-src}"
VER=1.58.2
SHA256=342385b6ca3b7c73455d7c80a13b7dbe4489e00bc3bd4c5bd6ed4dce421e374a
TARBALL="pango-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/p/pango1.0/pango1.0_$VER.orig.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "pango-$VER" ] || tar -xf "$TARBALL"
cd "pango-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release --wrap-mode=nofallback \
  -Dcairo=enabled -Dfontconfig=enabled -Dfreetype=enabled \
  -Dintrospection=disabled -Dlibthai=disabled -Dxft=disabled -Dsysprof=disabled \
  -Dbuild-testsuite=false -Dbuild-examples=false -Ddocumentation=false -Dman-pages=false -Dgtk_doc=false
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
