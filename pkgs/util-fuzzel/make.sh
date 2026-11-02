SRC="${HDX_SRC:-/hdxp/src/util-fuzzel-src}"
VER=1.14.1
SHA256=a3af48d00d5cb7cb5526ab86bd632c62dbea5901693fdd746a2e7bb5bd64cf04
TARBALL="fuzzel-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://codeberg.org/dnkl/fuzzel/releases/download/$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "fuzzel-$VER" ] || tar xf "$TARBALL"
cd "fuzzel-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
rm -rf build
meson setup build --prefix=/usr/local --buildtype=release \
  -Denable-cairo=disabled -Dpng-backend=none -Dsvg-backend=none
meson compile -C build
$SU meson install -C build
