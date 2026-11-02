SRC="${HDX_SRC:-/hdxp/src/devel-m4-src}"
VER=1.4.19
SHA256=REPLACE_ME
TARBALL="m4-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://ftp.gnu.org/gnu/m4/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "m4-$VER" ] || tar xf "$TARBALL"
cd "m4-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
# gcc 15 defaults to C23, which breaks old gnulib code
CFLAGS="-O2 -std=gnu17" ./configure --prefix=/usr/local --disable-nls
make -j"$(nproc 2>/dev/null || echo 1)"
$SU make install
