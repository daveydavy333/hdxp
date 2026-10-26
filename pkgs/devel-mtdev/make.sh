SRC="${HDX_SRC:-/hdxp/src/devel-mtdev-src}"
VER=1.1.7
SHA256=a55bd02a9af4dd266c0042ec608744fff3a017577614c057da09f1f4566ea32c
TARBALL="mtdev-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/m/mtdev/mtdev_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "mtdev-$VER" ] || tar xzf "$TARBALL"
cd "mtdev-$VER"
./configure --prefix=/usr/local --disable-static
make -j"$(nproc 2>/dev/null || echo 1)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
