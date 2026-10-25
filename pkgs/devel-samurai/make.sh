SRC="${HDX_SRC:-/hdxp/src/devel-samurai-src}"
VER=1.3
SHA256=1bc020a9e133432df51911ac71cc34322f828934d9a2282ba2916d88c15976af
TARBALL="samurai-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/michaelforney/samurai/releases/download/$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "samurai-$VER" ] || tar xzf "$TARBALL"
cd "samurai-$VER"
make -j"$(nproc 2>/dev/null || echo 1)" PREFIX=/usr/local
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install PREFIX=/usr/local
$SU ln -sf samu /usr/local/bin/ninja
