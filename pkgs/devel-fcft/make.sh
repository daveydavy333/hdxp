SRC="${HDX_SRC:-/hdxp/src/devel-fcft-src}"
VER=3.3.3
SHA256=67c587e9400405749c700d6f19e5bf6f1607195e5740f90688425073451c6983
TARBALL="fcft-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/f/fcft/fcft_$VER.orig.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "fcft-$VER" ] || tar xJf "$TARBALL"
cd "fcft-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib \
  -Ddocs=disabled -Dgrapheme-shaping=disabled -Drun-shaping=disabled \
  -Dsvg-backend=nanosvg -Dexamples=false
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
