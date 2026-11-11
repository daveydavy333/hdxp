set -e
SRC="${HDX_SRC:-/hdxp/src/util-slurp-src}"
VER=1.5.0
SHA256=0fa880d4a93e1c795e3b5929fbea47546df0955bea34fc2f7ffeb1751678f663
TARBALL="slurp-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/emersion/slurp/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "slurp-$VER" ] || tar -xf "$TARBALL"
cd "slurp-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release --wrap-mode=nofallback \
  -Dwerror=false -Dman-pages=auto
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
