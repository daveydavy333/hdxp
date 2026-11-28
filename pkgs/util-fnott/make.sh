SRC="${HDX_SRC:-/hdxp/src/util-fnott-src}"
PKG="${HDX_PKG:-util-fnott}"
VER=1.8.0
SHA256=bcb035b8732e440d68d401f5eda8605e6705ada403d0eb5c2084cb94b91c0626
TARBALL="fnott_$VER+ds.orig.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/f/fnott/fnott_$VER+ds.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "fnott-$VER+ds" ] || tar xf "$TARBALL"
cd "fnott-$VER+ds"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
NSVG=239e102ec2c691f2902e20ace2ed36ee4a35cfe6
NSVG_SHA256=2bc68bdb518d7800252042e5cad50a0ab321596f0cbf49ef2a752926329063d2
NSVG_TARBALL="nanosvg-$NSVG.tar.gz"
[ -f "../$NSVG_TARBALL" ] || curl -fL -o "../$NSVG_TARBALL" "https://github.com/memononen/nanosvg/archive/$NSVG.tar.gz"
( cd .. && echo "$NSVG_SHA256  $NSVG_TARBALL" | sha256sum -c - )
[ -d "../nanosvg-$NSVG" ] || ( cd .. && tar xf "$NSVG_TARBALL" )
mkdir -p 3rd-party/nanosvg/src nanosvg
cp "../nanosvg-$NSVG/src/nanosvg.h" "../nanosvg-$NSVG/src/nanosvgrast.h" 3rd-party/nanosvg/src/
cp "../nanosvg-$NSVG/src/nanosvg.h" "../nanosvg-$NSVG/src/nanosvgrast.h" nanosvg/
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release -Ddocs=enabled -Dsystemd-units-dir=/usr/local/lib/systemd/user
meson compile -C build
$SU /usr/local/bin/meson install -C build --no-rebuild
# the install log is what uninstall.sh removes, so nothing is guessed on removal
$SU install -Dm644 build/meson-logs/install-log.txt "/usr/local/share/hdxp-manifests/$PKG.txt"
sync
