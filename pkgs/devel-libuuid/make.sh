SRC="${HDX_SRC:-/hdxp/src/devel-libuuid-src}"
VER=2.42.2
SHA256=03a05d3adf9602ef128f2da05b84b3205ce60c351e5737c0370f74000679ce8a
TARBALL="util-linux-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/u/util-linux/util-linux_$VER.orig.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
if [ ! -d "util-linux-$VER" ]; then
  xz -t "$TARBALL" || { echo "xz test of $TARBALL failed"; exit 1; }
  xz -dc "$TARBALL" | tar -x || { rm -rf "util-linux-$VER"; echo "extraction failed"; exit 1; }
fi
cd "util-linux-$VER"
./configure --prefix=/usr/local --libdir=/usr/local/lib --disable-static \
  --disable-all-programs --enable-libuuid --disable-uuidd --disable-nls --disable-bash-completion \
  --disable-asciidoc --disable-poman --without-python --without-systemd --without-udev \
  --without-ncurses --without-readline --without-tinfo
make -j"${HDX_JOBS:-$(nproc)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
