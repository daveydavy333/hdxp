SRC="${HDX_SRC:-/hdxp/src/util-tmux-src}"
VER=3.4
SHA256=551ab8dea0bf505c0ad6b7bb35ef567cdde0ccb84357df142c254f35a23e19aa
TARBALL="tmux_3.4.orig.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/t/tmux/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "tmux-$VER" ] || tar xf "$TARBALL"
cd "tmux-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
./configure --prefix=/usr/local
make -j"$(nproc 2>/dev/null || echo 1)"
$SU make install
