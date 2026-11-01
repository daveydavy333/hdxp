SRC="${HDX_SRC:-/hdxp/src/devel-ncurses-src}"
VER=6.4-20240113
SHA256=37a12a0f8ae2605012c9a164dd286b0cfa02b51b5055836d09eb3d597fc351b1
TARBALL="ncurses_6.4+20240113.orig.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/n/ncurses/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "ncurses-6.4-20240113" ] || tar xf "$TARBALL"
cd "ncurses-6.4-20240113"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
# wide-char build, headers straight in /usr/local/include, terminfo database in /usr/local/share/terminfo
./configure --prefix=/usr/local --with-shared --without-normal --without-debug \
    --without-ada --without-cxx --without-cxx-binding --without-manpages --without-tests \
    --enable-widec --enable-overwrite --enable-pc-files --with-pkg-config-libdir=/usr/local/lib/pkgconfig \
    --with-terminfo-dirs=/usr/local/share/terminfo:/etc/terminfo:/lib/terminfo:/usr/share/terminfo \
    --with-default-terminfo-dir=/usr/local/share/terminfo
make -j"$(nproc 2>/dev/null || echo 1)"
$SU make install
# programs that ask for plain libncurses (no w) get the wide one
for l in ncurses form panel menu; do
    $SU ln -sf "lib${l}w.so" "/usr/local/lib/lib${l}.so"
    [ -f "/usr/local/lib/pkgconfig/${l}w.pc" ] && $SU ln -sf "${l}w.pc" "/usr/local/lib/pkgconfig/${l}.pc"
done
