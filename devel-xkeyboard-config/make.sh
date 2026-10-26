SRC="${HDX_SRC:-/hdxp/src/devel-xkeyboard-config-src}"
VER=2.48
SHA256=b77041324f0109f77161ee43743fe04baa485866af8460d31e476ad3f7648fd5
TARBALL="xkeyboard-config-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://www.x.org/releases/individual/data/xkeyboard-config/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "xkeyboard-config-$VER" ] || tar xJf "$TARBALL"
cd "xkeyboard-config-$VER"
rm -rf build
meson setup build --prefix=/usr/local -Dnls=false -Dxorg-rules-symlinks=false
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
