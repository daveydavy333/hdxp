SRC="${HDX_SRC:-/hdxp/src/devel-libei-src}"
VER=1.5.0
SHA256=da1fba92daccd0667bc46c3ee952d4ae8cfc6bdb4c0bb4d34df26528fb240618
TARBALL="libei-$VER.tar.bz2"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/libe/libei/libei_$VER.orig.tar.bz2"
echo "$SHA256  $TARBALL" | sha256sum -c -
if [ ! -d "libei-$VER" ]; then
  bzip2 -t "$TARBALL" || { echo "bzip2 test of $TARBALL failed"; exit 1; }
  bzip2 -dc "$TARBALL" | tar -x || { rm -rf "libei-$VER"; echo "extraction failed"; exit 1; }
fi
# libei's protocol code generator needs the python module jinja2
[ -d pyenv ] || python3 -m venv pyenv
./pyenv/bin/python -m pip install Jinja2==3.1.6 MarkupSafe==3.0.3
PATH="$SRC/pyenv/bin:$PATH"
export PATH
cd "libei-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release \
  -Dtests=disabled -Dliboeffis=disabled
meson compile -C build
$SU meson install -C build
