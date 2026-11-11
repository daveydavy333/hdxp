set -e
SRC="${HDX_SRC:-/hdxp/src/util-grim-src}"
VER=1.4.0
SHA256=b6786e889ed93568634189a59f6b6429c041bf74883c10e8b6e2ed6772ae7ffb
TARBALL="grim-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/emersion/grim/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "grim-$VER" ] || tar -xf "$TARBALL"
cd "grim-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release --wrap-mode=nofallback \
  -Dwerror=false -Djpeg=enabled -Dman-pages=auto
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
