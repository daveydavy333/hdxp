VER=1.6.12
SHA=73dd5d5c7e67993d33de0930df5189bd5cb8883d8e3c81ab7866b1370f029eb3
TAR="pipewire-$VER.tar.gz"
SRC="${HDX_SRC:-/hdxp/src/devel-pipewire-src}"
PKG="${HDX_PKG:-devel-pipewire}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"
command -v meson >/dev/null || { echo "error: meson not found (devel-meson)"; exit 1; }
JOBS=$(nproc 2>/dev/null || echo 1)

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://github.com/PipeWire/pipewire/archive/refs/tags/1.6.12.tar.gz"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "pipewire-$VER" ] || tar -xf "$TAR"
cd "pipewire-$VER"

# libudev comes from sys-eudev or devel-libudev-zero, so it is not in deps
pkg-config --exists libudev || { echo "error: pkg-config module 'libudev' not found"; exit 1; }
RL=disabled
pkg-config --exists readline && RL=enabled

# a failed build is resumed, not restarted: rm -rf build to force a reconfigure
# only what a desktop needs: alsa (+ the ALSA plugin so alsa apps use pipewire), udev, dbus, the pulse server and pw-cat.
# no systemd/logind, jack, v4l2, bluez, gstreamer, ffmpeg, vulkan, x11, avahi, ...
if [ ! -f build/build.ninja ]; then
    rm -rf build
    meson setup build --prefix=/usr/local --libdir=lib --buildtype=release \
        -Dauto_features=disabled \
        '-Dsession-managers=[]' \
        -Ddocs=disabled -Dman=disabled -Dexamples=disabled -Dtests=disabled -Dinstalled_tests=disabled \
        -Dalsa=enabled -Dudev=enabled -Ddbus=enabled -Dpipewire-alsa=enabled -Dsndfile=enabled -Dpw-cat=enabled \
        -Dreadline=$RL \
        -Dpipewire-jack=disabled -Djack=disabled -Dpipewire-v4l2=disabled -Dv4l2=disabled \
        -Dlibcamera=disabled -Dbluez5=disabled -Dgstreamer=disabled -Dgstreamer-device-provider=disabled \
        -Dffmpeg=disabled -Dvulkan=disabled -Dx11=disabled -Dlibsystemd=disabled -Dlogind=disabled \
        -Dsystemd-user-service=disabled -Dsystemd-system-service=disabled -Drlimits-install=false \
        -Dlibusb=disabled -Davahi=disabled -Droc=disabled -Dlv2=disabled -Dlibpulse=disabled \
        -Decho-cancel-webrtc=disabled -Dlibmysofa=disabled -Dopus=disabled -Dsdl2=disabled
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

for f in bin/pipewire bin/pipewire-pulse bin/pw-cli bin/pw-cat lib/libpipewire-0.3.so lib/pkgconfig/libpipewire-0.3.pc lib/pkgconfig/libspa-0.2.pc; do
    [ -s "/usr/local/$f" ] || { echo "error: /usr/local/$f is empty or missing"; exit 1; }
done
echo "note: the ALSA plugin config was installed as: $(find /usr/local -name 50-pipewire.conf 2>/dev/null | head -n1)"
echo "note: alsa-lib only loads /etc/alsa/conf.d, misc-pwscripts links the pipewire ALSA snippets there; once linked, ALSA programs need pipewire running or -D plughw:0"
