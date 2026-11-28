SRC="${HDX_SRC:-/hdxp/src/util-chafa-src}"
PKG="${HDX_PKG:-util-chafa}"
VER=1.18.3
SHA256=fb995ef21dce6c73dd0dd454ba3e0f7fac08e053ea16060a2e5ce69a3746ee27
TARBALL="chafa-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/hpjansson/chafa/releases/download/$VER/chafa-$VER.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "chafa-$VER" ] || tar xf "$TARBALL"
cd "chafa-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
./configure --prefix=/usr/local --disable-man --disable-static --without-tiff --without-avif --without-jxl
make -j"$(nproc 2>/dev/null || echo 1)"
STAGE="$SRC/stage"
rm -rf "$STAGE"
make install DESTDIR="$STAGE"
( cd "$STAGE" && find . \( -type f -o -type l \) | sed 's|^\.||' ) > "$SRC/manifest.txt"
$SU cp -R "$STAGE"/. /
$SU install -Dm644 "$SRC/manifest.txt" "/usr/local/share/hdxp-manifests/$PKG.txt"
sync
