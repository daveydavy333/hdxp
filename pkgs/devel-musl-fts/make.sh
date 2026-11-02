SRC="${HDX_SRC:-/hdxp/src/devel-musl-fts-src}"
VER=1.2.7
SHA256=49ae567a96dbab22823d045ffebe0d6b14b9b799925e9ca9274d47d26ff482a6
TARBALL="musl-fts-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/pullmoll/musl-fts/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "musl-fts-$VER" ] || tar xf "$TARBALL"
cd "musl-fts-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
# the autotools setup is skipped: fts.c only needs these two defines
printf '#define HAVE_DIRFD 1\n#define HAVE_DECL_MAX 1\n' > config.h
cc -O2 -fPIC -std=gnu17 -I. -c fts.c -o fts.o
ar rcs libfts.a fts.o
cat > musl-fts.pc <<PC
prefix=/usr/local
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: musl-fts
Description: Implementation of fts(3) functions for musl libc
Version: $VER
Libs: -L\${libdir} -lfts
Cflags: -I\${includedir}
PC
$SU mkdir -p /usr/local/lib/pkgconfig /usr/local/include
$SU cp libfts.a /usr/local/lib/libfts.a
$SU cp fts.h /usr/local/include/fts.h
$SU cp musl-fts.pc /usr/local/lib/pkgconfig/musl-fts.pc
