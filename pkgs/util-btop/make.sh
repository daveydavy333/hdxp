SRC="${HDX_SRC:-/hdxp/src/util-btop-src}"
VER=1.4.8
SHA256=67e07c21b770a6d884c5e50ba1d2cfc90732ea57459367d8732ec7ecbeb3be5f
TARBALL="btop-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/aristocratos/btop/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "btop-$VER" ] || tar xf "$TARBALL"
cd "btop-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
# btop needs a C++23 compiler (gcc 14 or newer)
make -j"$(nproc 2>/dev/null || echo 1)"
$SU make install PREFIX=/usr/local
