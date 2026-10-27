SRC="${HDX_SRC:-/hdxp/src/devel-gperf-src}"
VER=3.0.4
SHA256=767112a204407e62dbc3106647cf839ed544f3cf5d0f0523aaa2508623aad63e
TARBALL="gperf-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/g/gperf/gperf_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "gperf-$VER" ] || tar xzf "$TARBALL"
cd "gperf-$VER"
CFLAGS="-O2 -std=gnu17 -include string.h" CXXFLAGS="-O2 -std=gnu++98" ./configure --prefix=/usr/local
make -j"$(nproc 2>/dev/null || echo 1)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
