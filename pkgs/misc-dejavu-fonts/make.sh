SRC="${HDX_SRC:-/hdxp/src/misc-dejavu-fonts-src}"
VER=2.37
SHA256=fa9ca4d13871dd122f61258a80d01751d603b4d3ee14095d65453b4e846e17d7
TARBALL="dejavu-fonts-ttf-$VER.tar.bz2"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "dejavu-fonts-ttf-$VER" ] || tar xjf "$TARBALL"
cd "dejavu-fonts-ttf-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU mkdir -p /usr/local/share/fonts/dejavu
for f in ttf/*.ttf; do
  $SU cp -f "$f" /usr/local/share/fonts/dejavu/
done
$SU chmod 644 /usr/local/share/fonts/dejavu/*.ttf
if command -v fc-cache >/dev/null 2>&1; then $SU fc-cache -f /usr/local/share/fonts/dejavu; fi
