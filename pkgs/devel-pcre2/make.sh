SRC="${HDX_SRC:-/hdxp/src/devel-pcre2-src}"
VER=10.49
SHA256=929f0b20e62879252a15886b06c89f1edef61a363cbd5826fb041080a5e557ae
TARBALL="pcre2-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/p/pcre2/pcre2_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "pcre2-$VER" ] || tar -xf "$TARBALL"
cd "pcre2-$VER"
./configure --prefix=/usr/local --libdir=/usr/local/lib --disable-static --enable-jit
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
