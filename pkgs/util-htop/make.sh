SRC="${HDX_SRC:-/hdxp/src/util-htop-src}"
VER=3.5.3
SHA256=a8b164386494cb85bb255a415a3f5f80afe7a0c4491da5d113b3a0f951087e65
TARBALL="htop-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/htop-dev/htop/releases/download/$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "htop-$VER" ] || tar xf "$TARBALL"
cd "htop-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
# the wide-character ncurses (needed for unicode meters) has no pkg-config file here, so just
# try unicode first and fall back to plain ascii if configure cannot find it
./configure --prefix=/usr/local --enable-unicode || ./configure --prefix=/usr/local --disable-unicode
make -j"$(nproc 2>/dev/null || echo 1)"
$SU make install
