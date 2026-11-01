SRC="${HDX_SRC:-/hdxp/src/devel-libevent-src}"
VER=2.1.12-stable
SHA256=92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb
TARBALL="libevent_2.1.12-stable.orig.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/libe/libevent/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "libevent-$VER" ] || tar xf "$TARBALL"
cd "libevent-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
./configure --prefix=/usr/local --disable-static --disable-openssl --disable-samples \
    --disable-libevent-regress
make -j"$(nproc 2>/dev/null || echo 1)"
$SU make install
