SRC="${HDX_SRC:-/hdxp/src/devel-libxml2-src}"
VER=2.15.4
SHA256=5868d20db42ee21e4881bc53050c7fa226286a277cb3d0543f76b81f7571e934
TARBALL="libxml2-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/libx/libxml2/libxml2_$VER+dfsg.orig.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
if [ ! -d "libxml2-$VER" ]; then
  xz -t "$TARBALL" || { echo "xz test of $TARBALL failed"; exit 1; }
  xz -dc "$TARBALL" | tar -x || { rm -rf "libxml2-$VER"; echo "extraction failed"; exit 1; }
fi
cd "libxml2-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release \
  -Dpython=disabled -Ddocs=disabled -Dreadline=disabled -Dhistory=disabled -Dhttp=disabled -Dzlib=enabled
meson compile -C build
$SU meson install -C build
