VER=1.5.7
SHA=37d7284556b20954e56e1ca85b80226768902e2edabd3b649e9e72c0c9012ee3
TAR="zstd-$VER.tar.gz"
SRC="${HDX_SRC:-/hdxp/src/devel-zstd-src}"
PKG="${HDX_PKG:-devel-zstd}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
JOBS=$(nproc 2>/dev/null || echo 1)
FLAGS="PREFIX=/usr/local HAVE_ZLIB=0 HAVE_LZMA=0 HAVE_LZ4=0 ZSTD_LEGACY_SUPPORT=0"

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://github.com/facebook/zstd/archive/refs/tags/v1.5.7.tar.gz"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "zstd-$VER" ] || tar -xf "$TAR"
cd "zstd-$VER"

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

for f in bin/zstd lib/libzstd.so lib/pkgconfig/libzstd.pc; do
    [ -s "/usr/local/$f" ] || { echo "error: /usr/local/$f is empty or missing"; exit 1; }
done
