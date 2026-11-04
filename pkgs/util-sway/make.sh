SRC="${HDX_SRC:-/hdxp/src/util-sway-src}"
VER=1.12
SHA256=28ace03bcd2579c118cbfa639ab39fe4935e23c810221b0b595d3e063e61b0b2
TARBALL="sway-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/s/sway/sway_$VER.orig.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "sway-$VER" ] || tar -xf "$TARBALL"
cd "sway-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release --wrap-mode=nofallback \
  -Dtray=disabled -Dgdk-pixbuf=disabled -Dman-pages=auto -Ddefault-wallpaper=false \
  -Dzsh-completions=false -Dbash-completions=false -Dfish-completions=false
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
