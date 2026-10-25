SRC="${HDX_SRC:-/hdxp/src/devel-pixman-src}"
VER=0.46.4
SHA256=d09c44ebc3bd5bee7021c79f922fe8fb2fb57f7320f55e97ff9914d2346a591c
TARBALL="pixman-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://www.cairographics.org/releases/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "pixman-$VER" ] || tar xzf "$TARBALL"
cd "pixman-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib -Dtests=disabled -Ddemos=disabled -Dgtk=disabled -Dlibpng=disabled
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
