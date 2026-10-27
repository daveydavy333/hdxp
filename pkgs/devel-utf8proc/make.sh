SRC="${HDX_SRC:-/hdxp/src/devel-utf8proc-src}"
VER=2.11.3
SHA256=abfed50b6d4da51345713661370290f4f4747263ee73dc90356299dfc7990c78
TARBALL="utf8proc-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/u/utf8proc/utf8proc_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "utf8proc-$VER" ] || tar xzf "$TARBALL"
cd "utf8proc-$VER"
make clean
make -j"$(nproc 2>/dev/null || echo 1)" prefix=/usr/local libdir=/usr/local/lib
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install prefix=/usr/local libdir=/usr/local/lib
