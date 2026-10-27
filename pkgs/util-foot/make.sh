SRC="${HDX_SRC:-/hdxp/src/util-foot-src}"
VER=1.27.0
SHA256=0cbdb3867517003796a395a6aa96304c639a160f5287b1cc167aabf9a13a473f
TARBALL="foot-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/f/foot/foot_$VER.orig.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "foot-$VER" ] || tar xJf "$TARBALL"
cd "foot-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib \
  -Ddocs=disabled -Dtests=false -Dgrapheme-clustering=disabled \
  -Dterminfo=disabled -Ddefault-terminfo=xterm-256color \
  -Dutmp-backend=none -Dthemes=true -Dime=true
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
