VER=1.11.1
SHA=683fed08a844ad012196381e40badf80c0bbe4962959761416d41c9e67d77ec7
TAR="lz4-$VER.tar.gz"
SRC="${HDX_SRC:-/hdxp/src/devel-lz4-src}"
PKG="${HDX_PKG:-devel-lz4}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
JOBS=$(nproc 2>/dev/null || echo 1)
FLAGS="PREFIX=/usr/local "

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://github.com/lz4/lz4/archive/refs/tags/v1.11.1.tar.gz"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "lz4-$VER" ] || tar -xf "$TAR"
cd "lz4-$VER"

make -j"$JOBS" $FLAGS

# install into a staging dir first: that gives the file list uninstall.sh needs
STAGE="$SRC/stage"
rm -rf "$STAGE"
make install $FLAGS DESTDIR="$STAGE"
(cd "$STAGE" && find . \( -type f -o -type l \) | sed 's|^\.||' | sort) > "$SRC/manifest.txt"
[ -s "$SRC/manifest.txt" ] || { echo "error: nothing was staged"; exit 1; }
$SU cp -a "$STAGE"/. /
$SU install -Dm644 "$SRC/manifest.txt" "/usr/local/share/hdxp-manifests/$PKG.txt"
sync

for f in bin/lz4 lib/liblz4.so lib/pkgconfig/liblz4.pc; do
    [ -s "/usr/local/$f" ] || { echo "error: /usr/local/$f is empty or missing"; exit 1; }
done
