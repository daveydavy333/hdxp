SRC="${HDX_SRC:-/hdxp/src/devel-libinput-src}"
VER=1.31.3
SHA256=1c37348cf34cc1ac85c94f41a978ec6a81613f7146bf994c9457137c4a85a249
TARBALL="libinput-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/libi/libinput/libinput_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "libinput-$VER-26191d396d74d505541d6311f0b4ae68d791b890" ] || tar xzf "$TARBALL"
cd "libinput-$VER-26191d396d74d505541d6311f0b4ae68d791b890"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib \
  -Dlibwacom=false -Ddebug-gui=false -Dtests=false -Ddocumentation=false \
  -Dinstall-tests=false -Dudev-dir=/usr/local/lib/udev
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
