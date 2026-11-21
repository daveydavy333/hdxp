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
# sample config: ALSA input (no pulse or pipewire here).
# listening to what the machine plays goes through the ALSA loopback card (snd-aloop, a module from base-kernel);
# source hdx_cap is a pcm defined in the asound.conf example below.
sed -e 's/^; method = alsa$/method = alsa/' \
    -e 's/^; source = hw:Loopback,1$/source = hdx_cap/' \
    example_files/config > cava.config.example
if [ "$NC_LD" = "" ]; then sed -i 's/^; output = noncurses$/output = noncurses/' cava.config.example; fi
$SU install -Dm755 cava /usr/local/bin/cava
$SU install -Dm644 cava.config.example /usr/local/share/cava/config.example
cat > asound.conf.example <<'ASOUNDEOF'
# Example /etc/asound.conf for cava: you still hear everything on the real sound card, and a copy
# goes into the ALSA loopback card (snd-aloop) that cava listens to.
#   - card 0 is the real sound card here; check yours with: aplay -l
#   - everything runs at 48000 Hz S16_LE: the multi plugin needs both outputs on the same rate
#   - dmix lets several programs play at the same time
#   - cava reads the pcm "hdx_cap" (set source = hdx_cap in its config), which resamples to what cava asks for
# test with the default device (speaker-test -D default -c2 -t sine -f 440 -l1), not with the pieces:
# hdx_tee has 4 channels and the dmix pcms only accept their own rate.
pcm.!default {
    type plug
    slave.pcm "hdx_route"
}
ctl.!default {
    type hw
    card 0
}
pcm.hdx_route {
    type route
    slave.pcm "hdx_tee"
    slave.channels 4
    ttable.0.0 1
    ttable.1.1 1
    ttable.0.2 1
    ttable.1.3 1
}
pcm.hdx_tee {
    type multi
    slaves.a.pcm "hdx_out"
    slaves.a.channels 2
    slaves.b.pcm "hdx_loop"
    slaves.b.channels 2
    bindings.0.slave a
    bindings.0.channel 0
    bindings.1.slave a
    bindings.1.channel 1
    bindings.2.slave b
    bindings.2.channel 0
    bindings.3.slave b
    bindings.3.channel 1
}
pcm.hdx_out {
    type dmix
    ipc_key 584101
    slave {
        pcm "hw:0,0"
        rate 48000
        format S16_LE
        channels 2
    }
}
pcm.hdx_loop {
    type dmix
    ipc_key 584102
    slave {
        pcm "hw:Loopback,0,0"
        rate 48000
        format S16_LE
        channels 2
    }
}
pcm.hdx_cap {
    type plug
    slave {
        pcm "hw:Loopback,1,0"
        rate 48000
        format S16_LE
        channels 2
    }
}
ASOUNDEOF
cat > 13-aloop.sh <<'ALOOPEOF'
#!/bin/sh
# load the ALSA loopback card for cava (needs CONFIG_SND_ALOOP=m in base-kernel; harmless if the module is missing)
if [ ! -d /sys/module/snd_aloop ]; then
    modprobe snd-aloop index=1 2>/dev/null || echo "13-aloop: snd-aloop module not available (rebuild base-kernel)"
fi
true
ALOOPEOF
$SU install -Dm644 asound.conf.example /usr/local/share/cava/asound.conf.example
$SU install -Dm755 13-aloop.sh /etc/rc.d/boot/13-aloop.sh
for t in output/themes/*; do $SU install -Dm644 "$t" "/usr/local/share/cava/themes/$(basename "$t")"; done
sync
[ -s /usr/local/bin/cava ]
echo "util-cava: first run: mkdir -p ~/.config/cava && cp /usr/local/share/cava/config.example ~/.config/cava/config && cava"
echo "util-cava: to visualize playback: rebuild base-kernel (snd-aloop module), reboot, then cp /usr/local/share/cava/asound.conf.example /etc/asound.conf"
