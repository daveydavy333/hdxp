SRC="${HDX_SRC:-/hdxp/src/util-swaybg-src}"
VER=1.2.2
SHA256=5fecf4cc1d6c961d93e3d6591a6481d3cc5a3e9af411bd2edd165eb4ba80e7ea
TARBALL="swaybg-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/s/swaybg/swaybg_$VER.orig.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "swaybg-$VER" ] || tar -xf "$TARBALL"
cd "swaybg-$VER"
rm -rf build
# gdk-pixbuf is enabled (not auto) so a missing devel-gdk-pixbuf fails the
# build loudly instead of silently producing a PNG-only swaybg.
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release --wrap-mode=nofallback \
  -Dgdk-pixbuf=enabled -Dman-pages=auto
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
