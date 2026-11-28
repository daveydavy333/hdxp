SRC="${HDX_SRC:-/hdxp/src/util-mandoc-src}"
PKG="${HDX_PKG:-util-mandoc}"
VER=1.14.6
SHA256=8bf0d570f01e70a6e124884088870cbed7537f36328d512909eb10cd53179d9c
TARBALL="mandoc-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL --tls-max 1.2 -o "$TARBALL" "https://mandoc.bsd.lv/snapshots/mandoc-$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "mandoc-$VER" ] || tar xf "$TARBALL"
cd "mandoc-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
cat > configure.local <<'CONF'
PREFIX=/usr/local
BINDIR=/usr/local/bin
SBINDIR=/usr/local/sbin
MANDIR=/usr/local/share/man
MANPATH_DEFAULT="/usr/local/share/man:/usr/share/man"
OSNAME="HDXI"
BUILD_DB=1
INSTALL_LIBMANDOC=0
STATIC=
CONF
./configure --prefix=/usr/local 
make -j"$(nproc 2>/dev/null || echo 1)"
STAGE="$SRC/stage"
rm -rf "$STAGE"
make install DESTDIR="$STAGE"
( cd "$STAGE" && find . \( -type f -o -type l \) | sed 's|^\.||' ) > "$SRC/manifest.txt"
$SU cp -R "$STAGE"/. /
$SU install -Dm644 "$SRC/manifest.txt" "/usr/local/share/hdxp-manifests/$PKG.txt"
# build the apropos/whatis database for the man pages that are already there (pages installed later: run makewhatis)
$SU /usr/local/sbin/makewhatis /usr/local/share/man || true
sync
