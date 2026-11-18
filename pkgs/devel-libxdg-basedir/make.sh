#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-devel-libxdg-basedir}"
SRC="${HDX_SRC:-/hdxp/src/devel-libxdg-basedir-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() { # need <pkg-config module> <min version>
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "devel-libxdg-basedir: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
fetch() { # fetch <url> <file> <sha256>
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "devel-libxdg-basedir: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}
mkdir -p "$SRC"
cd "$SRC"
VER=1.2.3
fetch "https://github.com/devnev/libxdg-basedir/archive/refs/tags/libxdg-basedir-$VER.tar.gz" \
    "libxdg-basedir-$VER.tar.gz" ff30c60161f7043df4dcc6e7cdea8e064e382aa06c73dcc3d1885c7d2c77451d
rm -rf "libxdg-basedir-$VER"
mkdir "libxdg-basedir-$VER"
tar xzf "libxdg-basedir-$VER.tar.gz" -C "libxdg-basedir-$VER" --strip-components=1
cd "libxdg-basedir-$VER"

# no autotools in hdxp: the library is one C file, build it by hand
${CC:-cc} ${CFLAGS:--O2} -fPIC -Iinclude -shared \
    -Wl,-soname,libxdg-basedir.so.1 -o libxdg-basedir.so.$VER src/basedir.c
cat > libxdg-basedir.pc <<PC
prefix=/usr/local
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: libxdg-basedir
Description: An implementation of the XDG Base Directory specification
Version: $VER
Libs: -L\${libdir} -lxdg-basedir
Cflags: -I\${includedir}
PC

$SU mkdir -p /usr/local/lib/pkgconfig /usr/local/include
$SU install -m755 libxdg-basedir.so.$VER /usr/local/lib/libxdg-basedir.so.$VER
$SU ln -sf libxdg-basedir.so.$VER /usr/local/lib/libxdg-basedir.so.1
$SU ln -sf libxdg-basedir.so.$VER /usr/local/lib/libxdg-basedir.so
$SU install -m644 include/basedir.h include/basedir_fs.h /usr/local/include/
$SU install -m644 libxdg-basedir.pc /usr/local/lib/pkgconfig/libxdg-basedir.pc
