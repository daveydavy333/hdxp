SRC="${HDX_SRC:-/hdxp/src/devel-readline-src}"
VER=8.3
SHA256=fe5383204467828cd495ee8d1d3c037a7eba1389c22bc6a041f627976f9061cc
TARBALL="readline-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/r/readline/readline_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "readline-$VER" ] || tar -xf "$TARBALL"
cd "readline-$VER"
./configure --prefix=/usr/local --libdir=/usr/local/lib --disable-static --with-curses
make -j"${HDX_JOBS:-$(nproc)}"
# readline.pc lists ncurses as a private requirement; if ncurses has no .pc file pkg-config would reject readline
if ! pkg-config --exists ncurses; then
  sed -i 's/^Requires.private: ncurses/Libs.private: -lncurses/' readline.pc
fi
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
