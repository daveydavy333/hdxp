SRC="${HDX_SRC:-/hdxp/src/devel-fribidi-src}"
VER=1.0.16
SHA256=1b1cde5b235d40479e91be2f0e88a309e3214c8ab470ec8a2744d82a5a9ea05c
TARBALL="fribidi-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/f/fribidi/fribidi_$VER.orig.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "fribidi-$VER" ] || tar -xf "$TARBALL"
cd "fribidi-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release --wrap-mode=nofallback \
  -Ddocs=false -Dtests=false -Dbin=false
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
