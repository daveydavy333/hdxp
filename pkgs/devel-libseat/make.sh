SRC="${HDX_SRC:-/hdxp/src/devel-libseat-src}"
VER=0.9.3
SHA256=302564d54d8e28191fadfd734f2675ecb0c9e0615a58011b89ef15dfa4dbaa96
TARBALL="seatd-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/s/seatd/seatd_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "seatd-$VER" ] || tar xzf "$TARBALL"
cd "seatd-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib \
  -Dserver=enabled -Dlibseat-seatd=enabled -Dlibseat-builtin=enabled \
  -Dlibseat-logind=disabled -Dman-pages=disabled -Dexamples=disabled
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
