# plain gcc build: upstream's autotools build needs autoconf, automake, libtool and autoconf-archive.
# inputs: alsa, fifo, shmem. outputs: ncurses (if ncursesw is found), noncurses, raw.
SRC="${HDX_SRC:-/hdxp/src/util-cava-src}"
VER=0.10.7
SHA256=43f994f7e609fab843af868d8a7bc21471ac62c5a4724ef97693201eac42e70a
TARBALL="cava-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/karlstav/cava/archive/refs/tags/$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "cava-$VER" ] || tar xf "$TARBALL"
cd "cava-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
FILES="cava.c cavacore.c config.c input/common.c input/fifo.c input/shmem.c input/alsa.c output/terminal_noncurses.c output/raw.c output/noritake.c"
DEFS="-DALSA"
NC_CF=""; NC_LD=""
if command -v ncursesw6-config >/dev/null 2>&1; then
  FILES="$FILES output/terminal_ncurses.c output/terminal_bcircle.c"
  DEFS="$DEFS -DNCURSES"
  NC_CF=$(ncursesw6-config --cflags); NC_LD=$(ncursesw6-config --libs)
  echo "util-cava: building with ncursesw output"
else
  echo "util-cava: ncursesw6-config not found, building noncurses output only"
fi
gcc -std=c99 -O2 -DNDEBUG $DEFS -DPACKAGE=\"cava\" -DVERSION=\"$VER\" \
  -D_POSIX_SOURCE -D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE_EXTENDED \
  -Wno-unused-result -I. -I/usr/local/include -I/usr/local/include/iniparser $NC_CF \
  -o cava $FILES \
  -L/usr/local/lib -lfftw3 -liniparser -lasound $NC_LD -lm -lrt -lpthread
# sample config: ALSA capture from the default device (no pulse or pipewire here).
# capturing what the machine plays needs snd-aloop (CONFIG_SND_ALOOP) in the kernel.
sed -e 's/^; method = alsa$/method = alsa/' \
    -e 's/^; source = hw:Loopback,1$/source = default/' \
    example_files/config > cava.config.example
if [ "$NC_LD" = "" ]; then sed -i 's/^; output = noncurses$/output = noncurses/' cava.config.example; fi
$SU install -Dm755 cava /usr/local/bin/cava
$SU install -Dm644 cava.config.example /usr/local/share/cava/config.example
for t in output/themes/*; do $SU install -Dm644 "$t" "/usr/local/share/cava/themes/$(basename "$t")"; done
sync
[ -s /usr/local/bin/cava ]
echo "util-cava: first run: mkdir -p ~/.config/cava && cp /usr/local/share/cava/config.example ~/.config/cava/config && cava"
