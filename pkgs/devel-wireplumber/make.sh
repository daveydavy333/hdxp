VER=0.5.19
SHA=f9454eae3a5a6ca903c05ead2a7e47d7d3957fb0ffac3ebb11d92842603ae80f
TAR="wireplumber-$VER.tar.gz"
SRC="${HDX_SRC:-/hdxp/src/devel-wireplumber-src}"
PKG="${HDX_PKG:-devel-wireplumber}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"
command -v meson >/dev/null || { echo "error: meson not found (devel-meson)"; exit 1; }
JOBS=$(nproc 2>/dev/null || echo 1)

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://github.com/PipeWire/wireplumber/archive/refs/tags/0.5.19.tar.gz"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "wireplumber-$VER" ] || tar -xf "$TAR"
cd "wireplumber-$VER"

# a failed build is resumed, not restarted: rm -rf build to force a reconfigure
# system lua (5.5 is supported), no systemd/elogind, no introspection, no tests
if [ ! -f build/build.ninja ]; then
    rm -rf build
    meson setup build --prefix=/usr/local --libdir=lib --buildtype=release \
        -Dsystem-lua=true -Dsystemd=disabled -Delogind=disabled -Dintrospection=disabled -Ddoc=disabled \
        -Dtests=false -Ddbus-tests=false -Dsystemd-user-service=false
fi
meson compile -C build -j "$JOBS"

# install into a staging dir first: that gives the file list uninstall.sh needs
# (DESTDIR is set to empty for the real install elsewhere because some meson post-install scripts run with set -u)
STAGE="$SRC/stage"
rm -rf "$STAGE"
env DESTDIR="$STAGE" meson install -C build --no-rebuild
(cd "$STAGE" && find . \( -type f -o -type l \) | sed 's|^\.||' | sort) > "$SRC/manifest.txt"
[ -s "$SRC/manifest.txt" ] || { echo "error: nothing was staged"; exit 1; }
$SU cp -a "$STAGE"/. /
$SU install -Dm644 "$SRC/manifest.txt" "/usr/local/share/hdxp-manifests/$PKG.txt"
sync

for f in bin/wireplumber bin/wpctl lib/libwireplumber-0.5.so; do
    [ -s "/usr/local/$f" ] || { echo "error: /usr/local/$f is empty or missing"; exit 1; }
done
