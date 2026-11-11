set -e
SRC="${HDX_SRC:-/hdxp/src/devel-libyaml-src}"
VER=0.2.5
SHA256=c642ae9b75fee120b2d96c712538bd2cf283228d2337df2cf2988e3c02678ef4
TARBALL="yaml-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
# The release asset ships a generated configure script; the plain git tag
# tarballs do not, and would need autoconf/automake/libtool.
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/yaml/libyaml/releases/download/$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "yaml-$VER" ] || tar -xf "$TARBALL"
cd "yaml-$VER"
make distclean >/dev/null 2>&1 || true
./configure --prefix=/usr/local --disable-static --enable-shared
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
