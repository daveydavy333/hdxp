VER=2.7.0
SHA=90f8d2fa8b5567c6899830ddef2c03f3c27960b11aca222fa17aa7ac613c2890
TAR="duktape-$VER.tar.xz"
SRC="${HDX_SRC:-/hdxp/src/devel-duktape-src}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://github.com/svaarala/duktape/releases/download/v$VER/$TAR"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "duktape-$VER" ] || tar -xf "$TAR"
cd "duktape-$VER"

# shared library + duktape.pc, installed to /usr/local/lib (polkitd's javascript rules engine)
make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr/local LIBDIR=/lib -j"$(nproc)"
$SU make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr/local LIBDIR=/lib install
sync
[ -s /usr/local/lib/pkgconfig/duktape.pc ] || { echo "error: /usr/local/lib/pkgconfig/duktape.pc is missing"; exit 1; }
