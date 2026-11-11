set -e
SRC="${HDX_SRC:-/hdxp/src/util-wl-clipboard-src}"
VER=2.3.0
SHA256=b4dc560973f0cd74e02f817ffa2fd44ba645a4f1ea94b7b9614dacc9f895f402
TARBALL="wl-clipboard-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/bugaevc/wl-clipboard/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "wl-clipboard-$VER" ] || tar -xf "$TARBALL"
cd "wl-clipboard-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release --wrap-mode=nofallback \
  -Dprotocols=enabled -Dzshcompletiondir=no -Dfishcompletiondir=no
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
