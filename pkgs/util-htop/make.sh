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
# unicode needs the wide-character ncurses; fall back if the ncurses port lacks it
if pkg-config --exists ncursesw 2>/dev/null; then UNI=--enable-unicode; else UNI=--disable-unicode; fi
./configure --prefix=/usr/local $UNI
make -j"$(nproc 2>/dev/null || echo 1)"
$SU make install
