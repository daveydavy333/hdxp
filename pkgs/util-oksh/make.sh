SRC="${HDX_SRC:-/hdxp/src/util-oksh-src}"
PKG="${HDX_PKG:-util-oksh}"
VER=7.9
SHA256=51b2d92515950c959dbf24f6fc33336db8c0526c2a50fee4ca598a18a6114a49
TARBALL="oksh-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/ibara/oksh/releases/download/oksh-$VER/oksh-$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "oksh-$VER" ] || tar xf "$TARBALL"
cd "oksh-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
./configure --prefix=/usr/local --cflags="-g -O2 -DNCURSES_ENABLE_STDBOOL_H=1"
make -j"$(nproc 2>/dev/null || echo 1)"
STAGE="$SRC/stage"
rm -rf "$STAGE"
make install DESTDIR="$STAGE"
( cd "$STAGE" && find . \( -type f -o -type l \) | sed 's|^\.||' ) > "$SRC/manifest.txt"
$SU cp -R "$STAGE"/. /
$SU install -Dm644 "$SRC/manifest.txt" "/usr/local/share/hdxp-manifests/$PKG.txt"
# list it in /etc/shells (needed for login shells, ssh and chsh)
if [ -f /etc/shells ]; then
    grep -qx /usr/local/bin/oksh /etc/shells || echo /usr/local/bin/oksh | $SU tee -a /etc/shells >/dev/null
fi
sync
