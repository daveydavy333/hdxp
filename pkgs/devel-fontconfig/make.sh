SRC="${HDX_SRC:-/hdxp/src/devel-fontconfig-src}"
VER=2.17.1
SHA256=9f5cae93f4fffc1fbc05ae99cdfc708cd60dfd6612ffc0512827025c026fa541
TARBALL="fontconfig-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://gitlab.freedesktop.org/api/v4/projects/890/packages/generic/fontconfig/$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "fontconfig-$VER" ] || tar xJf "$TARBALL"
cd "fontconfig-$VER"
./configure --prefix=/usr/local --sysconfdir=/usr/local/etc --localstatedir=/var \
  --disable-static --disable-docs --disable-nls --disable-cache-build \
  --with-default-fonts=/usr/local/share/fonts --with-add-fonts=/usr/share/fonts
# the tarball ships the generated fcobjshash.h, but make regenerates it (and wants gperf) when timestamps
# come out in the wrong order after extraction; touch the chain oldest to newest so it is left alone
if [ -f src/fcobjshash.h ]; then
  for f in src/fcobjshash.gperf.h src/stamp-fcobjshash.gperf src/fcobjshash.gperf src/fcobjshash.h; do
    [ -f "$f" ] && { touch "$f"; sleep 1; }
  done
fi
make -j"$(nproc 2>/dev/null || echo 1)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
