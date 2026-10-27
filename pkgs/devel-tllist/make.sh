SRC="${HDX_SRC:-/hdxp/src/devel-tllist-src}"
VER=1.1.0
SHA256=85d33ecfa67b47ddf9586fda37b74d6f09c5b630275efdda6ab9d044e5da0ac2
TARBALL="tllist-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/t/tllist/tllist_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "tllist-$VER" ] || tar xzf "$TARBALL"
cd "tllist-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
