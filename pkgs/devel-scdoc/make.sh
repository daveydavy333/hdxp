SRC="${HDX_SRC:-/hdxp/src/devel-scdoc-src}"
VER=1.11.4
SHA256=REPLACE_ME
TARBALL="scdoc-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://git.sr.ht/~sircmpwn/scdoc/refs/download/$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "scdoc-$VER" ] || tar xf "$TARBALL"
cd "scdoc-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
make -j"$(nproc 2>/dev/null || echo 1)" PREFIX=/usr/local
$SU make install PREFIX=/usr/local
