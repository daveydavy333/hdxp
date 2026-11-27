# plain gcc build: upstream's autotools build needs autoconf, automake, libtool and autoconf-archive.
# inputs: pipewire (if libpipewire-0.3 is found), alsa, fifo, shmem. outputs: ncurses (if ncursesw is found), noncurses, raw.
# upstream's configure would pick pipewire up by itself; this build has to add the source file, -DPIPEWIRE and the libs by hand.
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
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"
FILES="cava.c cavacore.c config.c input/common.c input/fifo.c input/shmem.c input/alsa.c output/terminal_noncurses.c output/raw.c output/noritake.c"
DEFS="-DALSA"
NC_CF=""; NC_LD=""
PW_CF=""; PW_LD=""; HAVE_PW=0
if pkg-config --exists libpipewire-0.3 2>/dev/null; then
  FILES="$FILES input/pipewire.c"
  DEFS="$DEFS -DPIPEWIRE"
  PW_CF=$(pkg-config --cflags libpipewire-0.3); PW_LD=$(pkg-config --libs libpipewire-0.3)
  HAVE_PW=1
  echo "util-cava: building with pipewire input"
else
  echo "util-cava: libpipewire-0.3 not found, building without pipewire input (alsa only)"
fi
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
  -Wno-unused-result -I. -I/usr/local/include -I/usr/local/include/iniparser $NC_CF $PW_CF \
  -o cava $FILES \
  -L/usr/local/lib -lfftw3 -liniparser -lasound $NC_LD $PW_LD -lm -lrt -lpthread
# sample config: pipewire input when it is built in (captures the monitor of the default sink, i.e. whatever the machine
# plays), else plain alsa. the pcm names/loopback tee of earlier versions of this port are gone.
cp example_files/config cava.config.example
if [ "$HAVE_PW" -eq 1 ]; then
  sed -i '/^; method = pipewire$/{s/^; //;n;s/^; //}' cava.config.example
else
  sed -i '/^; method = alsa$/{s/^; //}' cava.config.example
fi
if [ "$NC_LD" = "" ]; then sed -i 's/^; output = noncurses$/output = noncurses/' cava.config.example; fi
$SU install -Dm755 cava /usr/local/bin/cava
$SU install -Dm644 cava.config.example /usr/local/share/cava/config.example
# earlier versions installed an ALSA loopback tee: remove their leftovers so they do not keep loading the loopback card
if grep -q snd-aloop /etc/rc.d/boot/13-aloop.sh 2>/dev/null; then $SU rm -f /etc/rc.d/boot/13-aloop.sh; fi
$SU rm -f /usr/local/share/cava/asound.conf.example
for t in output/themes/*; do $SU install -Dm644 "$t" "/usr/local/share/cava/themes/$(basename "$t")"; done
sync
[ -s /usr/local/bin/cava ]
echo "util-cava: first run: mkdir -p ~/.config/cava && cp /usr/local/share/cava/config.example ~/.config/cava/config && cava"
if [ "$HAVE_PW" -eq 1 ]; then echo "util-cava: pipewire input is built in: it listens to the default sink, so pipewire and wireplumber must be running"; fi
