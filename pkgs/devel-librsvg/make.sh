SRC="${HDX_SRC:-/hdxp/src/devel-librsvg-src}"
VER=2.63.4
SHA256=df1771eae2b7b169762d0af5f9ae5a1d24767888be5be6375fb1c0d618abc318
TARBALL="librsvg-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/libr/librsvg/librsvg_$VER+dfsg.orig.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
if [ ! -d "librsvg-$VER" ]; then
  xz -t "$TARBALL" || { echo "xz test of $TARBALL failed"; exit 1; }
  xz -dc "$TARBALL" | tar -x || { rm -rf "librsvg-$VER"; echo "extraction failed"; exit 1; }
fi
cd "librsvg-$VER"
# the musl rust target links statically by default, which cannot produce the shared library
PATH="/usr/local/bin:$PATH"
RUSTFLAGS="-C target-feature=-crt-static"
CARGO_HOME="$SRC/cargo-home"
CARGO_BUILD_JOBS="${HDX_JOBS:-4}"
export PATH RUSTFLAGS CARGO_HOME CARGO_BUILD_JOBS
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release \
  -Dpixbuf=disabled -Dpixbuf-loader=disabled -Dintrospection=disabled -Ddocs=disabled \
  -Dvala=disabled -Dtests=false -Davif=disabled
meson compile -C build
$SU meson install -C build
