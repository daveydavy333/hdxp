SRC="${HDX_SRC:-/hdxp/src/devel-meson-src}"
VER=1.12.1
SHA256=ab0a6ca09f8ef70c564c8241fb5a23957886a0b53fb58412b5e07eaf07dba743
TARBALL="meson-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/mesonbuild/meson/releases/download/$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "meson-$VER" ] || tar xzf "$TARBALL"
cd "meson-$VER"
printf '#!/bin/sh\nexec python3 /usr/local/lib/meson/meson.py "$@"\n' > "$SRC/meson-wrapper"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU rm -rf /usr/local/lib/meson
$SU mkdir -p /usr/local/lib/meson /usr/local/bin
$SU cp -R meson.py mesonbuild /usr/local/lib/meson/
$SU install -m 755 "$SRC/meson-wrapper" /usr/local/bin/meson
