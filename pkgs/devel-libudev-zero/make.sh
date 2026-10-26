SRC="${HDX_SRC:-/hdxp/src/devel-libudev-zero-src}"
VER=1.0.5
SHA256=bf4372f79ddbe6b0e266a3d2994ffac7018a7edf4f87632aecb5176565d96138
TARBALL="libudev-zero-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/illiliti/libudev-zero/archive/refs/tags/$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "libudev-zero-$VER" ] || tar xzf "$TARBALL"
cd "libudev-zero-$VER"
make clean
make -j"$(nproc 2>/dev/null || echo 1)" PREFIX=/usr/local
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install-shared PREFIX=/usr/local
