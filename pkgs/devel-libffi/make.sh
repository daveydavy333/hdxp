SRC="${HDX_SRC:-/hdxp/src/devel-libffi-src}"
VER=3.8.0
SHA256=7da3e2d9a171eb0a038f592ecad3ff2bb2550f3496d87b3b29ad0cf4430c0db4
TARBALL="libffi-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/libffi/libffi/releases/download/v$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "libffi-$VER" ] || tar xzf "$TARBALL"
cd "libffi-$VER"
./configure --prefix=/usr/local --disable-static --disable-docs
make -j"$(nproc 2>/dev/null || echo 1)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
