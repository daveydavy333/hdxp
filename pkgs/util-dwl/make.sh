SRC="${HDX_SRC:-/hdxp/src/util-dwl-src}"
VER=0.9
SHA256=51ed5da49942ca3272b6f2c4f1d7641b0b947a6eb1c264dce8a65b4d245596af
TARBALL="dwl-v$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://codeberg.org/dwl/dwl/releases/download/v$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
DIR="$(tar tzf "$TARBALL" | head -1 | cut -d/ -f1)"
[ -d "$DIR" ] || tar xzf "$TARBALL"
cd "$DIR"
# your own config: put it at /etc/hdxi/dwl-config.h before installing; otherwise dwl's default config.def.h is used
if [ -f /etc/hdxi/dwl-config.h ]; then cp /etc/hdxi/dwl-config.h config.h; else rm -f config.h; fi
make clean
make -j"$(nproc 2>/dev/null || echo 1)" PREFIX=/usr/local XWAYLAND= XLIBS=
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install PREFIX=/usr/local
