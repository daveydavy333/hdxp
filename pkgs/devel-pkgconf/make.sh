SRC="${HDX_SRC:-/hdxp/src/devel-pkgconf-src}"
VER=3.0.9
SHA256=6ab2d3b8087dcf500e34003a6a8934dca55d0a3d6066aeafb03c352db3e68bfd
TARBALL="pkgconf-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/pkgconf/pkgconf/releases/download/pkgconf-$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "pkgconf-$VER" ] || tar xJf "$TARBALL"
cd "pkgconf-$VER"
./configure --prefix=/usr/local --disable-static \
  --with-pkg-config-dir=/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig
make -j"$(nproc 2>/dev/null || echo 1)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
$SU ln -sf pkgconf /usr/local/bin/pkg-config
