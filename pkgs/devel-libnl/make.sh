SRC="${HDX_SRC:-/hdxp/src/devel-libnl-src}"
VER=3.11.0
SHA256=2a56e1edefa3e68a7c00879496736fdbf62fc94ed3232c0baba127ecfa76874d
TARBALL="libnl-$VER.tar.gz"
TAG="libnl$(echo "$VER" | tr . _)"
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
