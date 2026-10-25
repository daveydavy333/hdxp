SRC="${HDX_SRC:-/hdxp/src/devel-libdrm-src}"
VER=2.4.134
SHA256=ac5e74d157830eb8bee44c6a6bf3ad49774ef0dd2a72bdad74a8f20308b52a95
TARBALL="libdrm-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://dri.freedesktop.org/libdrm/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "libdrm-$VER" ] || tar xJf "$TARBALL"
cd "libdrm-$VER"
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib \
  -Dtests=false -Dman-pages=disabled -Dvalgrind=disabled -Dcairo-tests=disabled \
  -Dradeon=enabled -Damdgpu=enabled \
  -Dintel=disabled -Dnouveau=disabled -Dvmwgfx=disabled -Dfreedreno=disabled \
  -Dexynos=disabled -Detnaviv=disabled -Domap=disabled -Dtegra=disabled -Dvc4=disabled
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
