SRC="${HDX_SRC:-/hdxp/src/devel-libnl-src}"
VER=3.11.0
SHA256=REPLACE_ME
TARBALL="libnl-$VER.tar.gz"
TAG="libnl$(echo "$VER" | tr . _)"
if [ "$SHA256" = REPLACE_ME ]; then
    echo "devel-libnl: pin SHA256 in make.sh first (sha256sum of $TARBALL)" >&2
    exit 1
fi
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/thom311/libnl/releases/download/$TAG/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "libnl-$VER" ] || tar xzf "$TARBALL"
cd "libnl-$VER"
./configure --prefix=/usr/local --sysconfdir=/etc --disable-cli --disable-static
make -j"$(nproc 2>/dev/null || echo 1)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
