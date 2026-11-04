SRC="${HDX_SRC:-/hdxp/src/devel-cairo-src}"
VER=1.18.4
SHA256=445ed8208a6e4823de1226a74ca319d3600e83f6369f99b14265006599c32ccb
TARBALL="cairo-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/c/cairo/cairo_$VER.orig.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "cairo-$VER" ] || tar -xf "$TARBALL"
cd "cairo-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release --wrap-mode=nofallback \
  -Dfreetype=enabled -Dfontconfig=enabled -Dpng=enabled -Dzlib=enabled \
  -Dxcb=disabled -Dxlib=disabled -Dxlib-xcb=disabled -Dquartz=disabled -Ddwrite=disabled \
  -Dglib=disabled -Dspectre=disabled -Dlzo=disabled -Dsymbol-lookup=disabled -Dtests=disabled
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
