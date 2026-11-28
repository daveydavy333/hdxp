SRC="${HDX_SRC:-/hdxp/src/util-rsync-src}"
PKG="${HDX_PKG:-util-rsync}"
VER=3.5.2
SHA256=a10d591825251e070f74c98df3daad195def4ed81b4a2de16169026aea33f6c8
TARBALL="rsync-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://download.samba.org/pub/rsync/src/rsync-$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "rsync-$VER" ] || tar xf "$TARBALL"
cd "rsync-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
./configure --prefix=/usr/local --disable-idn --disable-md2man --disable-openssl --disable-acl-support --with-included-popt
make -j"$(nproc 2>/dev/null || echo 1)"
STAGE="$SRC/stage"
rm -rf "$STAGE"
make install DESTDIR="$STAGE"
( cd "$STAGE" && find . \( -type f -o -type l \) | sed 's|^\.||' ) > "$SRC/manifest.txt"
$SU cp -R "$STAGE"/. /
$SU install -Dm644 "$SRC/manifest.txt" "/usr/local/share/hdxp-manifests/$PKG.txt"
sync
