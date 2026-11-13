set -e
SRC="${HDX_SRC:-/hdxp/src/devel-alsa-lib-src}"
VER=1.2.16.1
SHA256=f740db7f488255944ffd4428416ee3390a96742856916433df468c281436480e
TARBALL="alsa-lib-$VER.tar.bz2"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/a/alsa-lib/alsa-lib_$VER.orig.tar.bz2"
echo "$SHA256  $TARBALL" | sha256sum -c -
# .bz2: needs a tar that can unpack it, or bzip2 on the side
[ -d "alsa-lib-$VER" ] || tar -xf "$TARBALL" || bzip2 -dc "$TARBALL" | tar -x
cd "alsa-lib-$VER"
make distclean >/dev/null 2>&1 || true
./configure --prefix=/usr/local --disable-static --enable-shared --disable-python
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
