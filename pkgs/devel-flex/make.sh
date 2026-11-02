SRC="${HDX_SRC:-/hdxp/src/devel-flex-src}"
VER=2.6.4
SHA256=e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995
TARBALL="flex-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/westes/flex/releases/download/v$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "flex-$VER" ] || tar xf "$TARBALL"
cd "flex-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
# gcc 15 defaults to C23, which breaks old code
CFLAGS="-O2 -std=gnu17" ./configure --prefix=/usr/local --disable-nls --disable-shared
make -j"$(nproc 2>/dev/null || echo 1)"
$SU make install
