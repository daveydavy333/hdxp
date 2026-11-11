set -e
SRC="${HDX_SRC:-/hdxp/src/util-swayimg-src}"
VER=5.7
SHA256=22e602cba022972ccc6e9701827135282679a5a8efc818132fdf56ce40a7d6fa
TARBALL="swayimg-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/artemsen/swayimg/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "swayimg-$VER" ] || tar -xf "$TARBALL"
cd "swayimg-$VER"
# swayimg takes its Lua from pkg-config; find what the lua port calls it.
PKGCONF=$(command -v pkgconf || command -v pkg-config)
LUAPC=
for n in lua lua5.4 lua-5.4 lua5.3 lua-5.3; do
  if "$PKGCONF" --exists "$n"; then LUAPC=$n; break; fi
done
[ -n "$LUAPC" ] || { echo "no lua .pc file found; devel-lua needs to install one" >&2; exit 1; }
echo "swayimg will use lua via $LUAPC"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release --wrap-mode=nofallback \
  -Dversion="$VER" -Dliblua="$LUAPC" \
  -Dpng=enabled -Djpeg=enabled -Dwebp=enabled -Dsvg=enabled \
  -Dexr=disabled -Dgif=disabled -Dheif=disabled -Davif=disabled -Djp2=disabled -Djxl=disabled \
  -Dkrita=disabled -Dtiff=disabled -Dsixel=disabled -Draw=disabled -Dvideo=disabled -Dexif=disabled \
  -Ddrm=disabled -Dbash=disabled -Dzsh=disabled -Ddesktop=false -Ddoc=false
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
