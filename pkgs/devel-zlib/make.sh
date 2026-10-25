SRC="${HDX_SRC:-/hdxp/src/devel-zlib-src}"
VER=1.3.2
SHA256=bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16
TARBALL="zlib-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/madler/zlib/releases/download/v$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "zlib-$VER" ] || tar xzf "$TARBALL"
cd "zlib-$VER"
./configure --prefix=/usr/local
make -j"$(nproc 2>/dev/null || echo 1)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
