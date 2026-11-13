set -e
SRC="${HDX_SRC:-/hdxp/src/util-alsa-utils-src}"
VER=1.2.15.2
SHA256=7aaaafbfb01942113ec0c31e51f705910e81079205088ca2f8f137a3869e1a3a
TARBALL="alsa-utils-$VER.tar.bz2"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/a/alsa-utils/alsa-utils_$VER.orig.tar.bz2"
echo "$SHA256  $TARBALL" | sha256sum -c -
# .bz2: needs a tar that can unpack it, or bzip2 on the side
[ -d "alsa-utils-$VER" ] || tar -xf "$TARBALL" || bzip2 -dc "$TARBALL" | tar -x
cd "alsa-utils-$VER"
# alsa-utils 1.2.15.2 typo: with alsa-lib newer than 1.2.15 aconnect's error handler
# uses "err" where the parameter is called "errcode", and the build stops there
sed -i 's/if (err)$/if (errcode)/; s/snd_strerror(err)/snd_strerror(errcode)/' seq/aconnect/aconnect.c
make distclean >/dev/null 2>&1 || true
# alsamixer needs ncurses. Off: bat (fftw), alsaconf (bash/dialog), man pages (xmlto/rst2man),
# nls, systemd units. State lives in /var/lib/alsa, restored by a udev rule when a card appears.
CPPFLAGS="${CPPFLAGS:-} -I/usr/local/include -I/usr/local/include/ncursesw" \
LDFLAGS="${LDFLAGS:-} -L/usr/local/lib" \
./configure --prefix=/usr/local --localstatedir=/var --disable-nls --disable-bat --disable-alsaconf \
  --disable-xmlto --disable-rst2man --with-udev-rules-dir=/lib/udev/rules.d \
  --with-systemdsystemunitdir=no
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
$SU mkdir -p /var/lib/alsa
