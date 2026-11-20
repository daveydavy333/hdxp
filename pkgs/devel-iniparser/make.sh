SRC="${HDX_SRC:-/hdxp/src/devel-iniparser-src}"
VER=4.2.6
SHA256=a0bd370713a744b1fa8ec27bba889ebf9dbd43060ec92e07fbe91fb43e3cb3ac
TARBALL="iniparser-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/ndevilla/iniparser/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "iniparser-$VER" ] || tar xf "$TARBALL"
cd "iniparser-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
# plain gcc build of the two source files, shared and static (-std=gnu17 for gcc 15)
gcc -O2 -std=gnu17 -fPIC -c src/iniparser.c -o iniparser.o
gcc -O2 -std=gnu17 -fPIC -c src/dictionary.c -o dictionary.o
gcc -shared -Wl,-soname,libiniparser.so.4 -o "libiniparser.so.$VER" iniparser.o dictionary.o
ar rcs libiniparser.a iniparser.o dictionary.o
cat > libiniparser.pc <<PC
prefix=/usr/local
libdir=\${prefix}/lib
includedir=\${prefix}/include/iniparser

Name: libiniparser
Description: C library for parsing INI-style files
Version: $VER
Libs: -L\${libdir} -liniparser
Cflags: -I\${includedir}
PC
$SU mkdir -p /usr/local/lib/pkgconfig /usr/local/include/iniparser
$SU install -m755 "libiniparser.so.$VER" "/usr/local/lib/libiniparser.so.$VER"
$SU ln -sf "libiniparser.so.$VER" /usr/local/lib/libiniparser.so.4
$SU ln -sf "libiniparser.so.$VER" /usr/local/lib/libiniparser.so
$SU install -m644 libiniparser.a /usr/local/lib/libiniparser.a
$SU install -m644 libiniparser.pc /usr/local/lib/pkgconfig/libiniparser.pc
$SU install -m644 src/iniparser.h src/dictionary.h /usr/local/include/iniparser/
sync
[ -s /usr/local/lib/libiniparser.a ] && [ -s /usr/local/include/iniparser/iniparser.h ]
