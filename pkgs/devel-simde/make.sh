# header-only: just copies the headers
SRC="${HDX_SRC:-/hdxp/src/devel-simde-src}"
VER=0.8.2
SHA256=ed2a3268658f2f2a9b5367628a85ccd4cf9516460ed8604eed369653d49b25fb
TARBALL="simde-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/simd-everywhere/simde/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "simde-$VER" ] || tar xf "$TARBALL"
cd "simde-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
cat > simde.pc <<PC
prefix=/usr/local
includedir=\${prefix}/include

Name: simde
Description: SIMD Everywhere (header-only)
Version: $VER
Cflags: -I\${includedir}
PC
$SU mkdir -p /usr/local/include /usr/local/lib/pkgconfig
$SU rm -rf /usr/local/include/simde
$SU cp -R simde /usr/local/include/simde
$SU install -m644 simde.pc /usr/local/lib/pkgconfig/simde.pc
sync
[ -s /usr/local/include/simde/simde-common.h ]
