SRC="${HDX_SRC:-/hdxp/src/util-nano-src}"
VER=7.2
SHA256=86f3442768bd2873cec693f83cdf80b4b444ad3cc14760b74361474fc87a4526
TARBALL="nano_7.2.orig.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/n/nano/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "nano-$VER" ] || tar xf "$TARBALL"
cd "nano-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
./configure --prefix=/usr/local --sysconfdir=/etc --enable-utf8 --disable-nls --disable-speller \
    --disable-libmagic
make -j"$(nproc 2>/dev/null || echo 1)"
$SU make install
