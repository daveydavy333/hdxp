VER=17.0
SHA=ed36c8a0cdff7b57382a258d3e1a916f42500fbafd64dd3c2e258ed8f017ee90
TAR="pulseaudio-$VER.tar.gz"
SRC="${HDX_SRC:-/hdxp/src/devel-libpulse-src}"
PKG="${HDX_PKG:-devel-libpulse}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"
command -v meson >/dev/null || { echo "error: meson not found (devel-meson)"; exit 1; }
JOBS=$(nproc 2>/dev/null || echo 1)

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://github.com/pulseaudio/pulseaudio/archive/refs/tags/v$VER.tar.gz"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "pulseaudio-$VER" ] || tar -xf "$TAR"
cd "pulseaudio-$VER"

# client library only (libpulse, libpulse-simple, pactl, paplay, pacat, ...): no daemon, PipeWire's pipewire-pulse is the server.
# the github tarball has no git metadata and upstream's version script needs this file
printf '%s' "$VER" > .tarball-version

# a failed build is resumed, not restarted: rm -rf build to force a reconfigure
if [ ! -f build/build.ninja ]; then
    rm -rf build
    meson setup build --prefix=/usr/local --libdir=lib --buildtype=release \
        -Dauto_features=disabled -Ddaemon=false -Dclient=true \
        -Ddoxygen=false -Dman=false -Dtests=false -Dgcov=false
fi
meson compile -C build -j "$JOBS"

# install into a staging dir first: that gives the file list uninstall.sh needs
STAGE="$SRC/stage"
rm -rf "$STAGE"
env DESTDIR="$STAGE" meson install -C build --no-rebuild
(cd "$STAGE" && find . \( -type f -o -type l \) | sed 's|^\.||' | sort) > "$SRC/manifest.txt"
[ -s "$SRC/manifest.txt" ] || { echo "error: nothing was staged"; exit 1; }
$SU cp -a "$STAGE"/. /
$SU install -Dm644 "$SRC/manifest.txt" "/usr/local/share/hdxp-manifests/$PKG.txt"
sync

for f in lib/libpulse.so lib/libpulse-simple.so lib/pkgconfig/libpulse.pc bin/pactl bin/paplay; do
    [ -s "/usr/local/$f" ] || { echo "error: /usr/local/$f is empty or missing"; exit 1; }
done
echo "note: client only. the server is pipewire-pulse (misc-pwscripts); programs find it at \$XDG_RUNTIME_DIR/pulse/native"
