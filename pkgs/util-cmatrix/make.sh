SRC="${HDX_SRC:-/hdxp/src/util-cmatrix-src}"
VER=2.0
SHA256=ad93ba39acd383696ab6a9ebbed1259ecf2d3cf9f49d6b97038c66f80749e99a
TARBALL="cmatrix-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/abishekvashok/cmatrix/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "cmatrix-$VER" ] || tar xf "$TARBALL"
cd "cmatrix-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
# plain gcc, no cmake. -std=gnu17: old-style declarations that gcc 15's C23 default rejects.
# USE_TIOCSTI is left out on purpose (kernels disable TIOCSTI); it only affected the -s lock mode.
if command -v ncurses6-config >/dev/null 2>&1; then
  CUR_CF=$(ncurses6-config --cflags); CUR_LD=$(ncurses6-config --libs)
else
  CUR_CF="-I/usr/local/include"; CUR_LD="-L/usr/local/lib -lncurses"
fi
gcc -O2 -std=gnu17 -DEXCLUDE_CONFIG_H -DVERSION=\"$VER\" \
  -DHAVE_SYS_IOCTL_H -DHAVE_UNISTD_H -DHAVE_TERMIOS_H -DHAVE_NCURSES_H \
  $CUR_CF -o cmatrix cmatrix.c $CUR_LD
$SU install -Dm755 cmatrix /usr/local/bin/cmatrix
$SU install -Dm644 cmatrix.1 /usr/local/share/man/man1/cmatrix.1
sync
[ -s /usr/local/bin/cmatrix ]
