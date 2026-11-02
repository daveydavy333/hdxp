SRC="${HDX_SRC:-/hdxp/src/util-nnn-src}"
VER=5.3
SHA256=c626d57d0aaa5effe04a7e8c24ec9000bc3aca012461b821ecd3c81f5131bb6d
TARBALL="nnn-v$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/jarun/nnn/releases/download/v$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "nnn-$VER" ] || tar xf "$TARBALL"
cd "nnn-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
LDLIBS=-lfts make -j"$(nproc 2>/dev/null || echo 1)"
$SU make install
