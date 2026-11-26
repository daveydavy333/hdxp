VER=6.12.1
SHA=70407e008298e9c5f2be993bc380ee7753774ed206aab31cf727d0e3c6dbe380
MOD=qtbase
TAR="$MOD-$VER.tar.gz"
SRC="${HDX_SRC:-/hdxp/src/skp-devel-qt6-base-src}"
PKG="${HDX_PKG:-skp-devel-qt6-base}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"
command -v cmake >/dev/null || { echo "error: cmake not found (devel-cmake)"; exit 1; }
NINJA=$(command -v ninja || command -v samu || true)
[ -n "$NINJA" ] || { echo "error: neither ninja nor samu found (devel-samurai)"; exit 1; }

# these come from other ports; udev can be sys-eudev or devel-libudev-zero, so it is not in deps
for m in libudev libinput xkbcommon wayland-client fontconfig dbus-1; do
    pkg-config --exists "$m" || { echo "error: pkg-config module '$m' not found"; exit 1; }
done

# qt links eat memory: allow about 1.5 GB per parallel job
JOBS=$(nproc 2>/dev/null || echo 1)
MEM=$(awk '/^MemTotal:/ {print int($2 / 1048576)}' /proc/meminfo 2>/dev/null || echo 4)
MAXJ=$((MEM * 2 / 3))
[ "$MAXJ" -ge 1 ] || MAXJ=1
[ "$JOBS" -le "$MAXJ" ] || JOBS=$MAXJ
echo "building with $JOBS parallel jobs"

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://github.com/qt/$MOD/archive/refs/tags/v$VER.tar.gz"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "$MOD-$VER" ] || tar -xf "$TAR"
cd "$MOD-$VER"

# use the system copy of a library when pkg-config knows it, qt's bundled copy otherwise
sysl() { if pkg-config --exists "$1"; then echo "-DFEATURE_system_$2=ON"; else echo "-DFEATURE_system_$2=OFF"; fi; }
if pkg-config --exists openssl; then
    SSL="-DFEATURE_ssl=ON -DFEATURE_openssl_linked=ON"
else
    SSL="-DFEATURE_ssl=OFF"
    echo "note: no openssl.pc found, QtNetwork is built without TLS (no https)"
fi

# a failed build is resumed, not restarted: rm -rf build to force a reconfigure
if [ ! -f build/build.ninja ]; then
    rm -rf build
    # software rendering only: no OpenGL/EGL, no X11, no glib, no ICU, no SQL
    cmake -S . -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_MAKE_PROGRAM="$NINJA" \
        -DBUILD_SHARED_LIBS=ON \
        -DINSTALL_BINDIR=lib/qt6/bin -DINSTALL_LIBEXECDIR=lib/qt6 -DINSTALL_ARCHDATADIR=lib/qt6 \
        -DINSTALL_DATADIR=share/qt6 -DINSTALL_INCLUDEDIR=include/qt6 -DINSTALL_MKSPECSDIR=lib/qt6/mkspecs \
        -DINSTALL_DOCDIR=share/doc/qt6 -DINSTALL_EXAMPLESDIR=share/doc/qt6/examples \
        -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DQT_BUILD_BENCHMARKS=OFF -DBUILD_TESTING=OFF \
        -DFEATURE_opengl=OFF -DFEATURE_egl=OFF -DFEATURE_vulkan=OFF -DFEATURE_xcb=OFF \
        -DFEATURE_eglfs=OFF -DFEATURE_kms=OFF \
        -DFEATURE_linuxfb=ON -DFEATURE_libinput=ON -DFEATURE_evdev=ON -DFEATURE_xkbcommon=ON \
        -DFEATURE_fontconfig=ON -DFEATURE_dbus=ON \
        -DFEATURE_glib=OFF -DFEATURE_icu=OFF -DFEATURE_cups=OFF -DFEATURE_gtk3=OFF -DFEATURE_sql=OFF \
        -DFEATURE_journald=OFF -DFEATURE_syslog=OFF -DFEATURE_zstd=OFF -DFEATURE_brotli=OFF \
        -DFEATURE_libproxy=OFF -DFEATURE_gssapi=OFF -DFEATURE_tslib=OFF -DFEATURE_mtdev=OFF \
        $(sysl zlib zlib) $(sysl libpng png) $(sysl libjpeg jpeg) $(sysl freetype2 freetype) \
        $(sysl harfbuzz harfbuzz) $(sysl libpcre2-16 pcre2) $SSL
fi
grep -E 'Wayland|libinput|D-Bus|OpenGL|OpenSSL|fontconfig|LinuxFB' build/config.summary || true

cmake --build build --parallel "$JOBS"
$SU cmake --install build

# the install manifest is what uninstall.sh removes, so nothing is guessed on removal
[ -s build/install_manifest.txt ] || { echo "error: no install manifest"; exit 1; }
$SU install -Dm644 build/install_manifest.txt "/usr/local/share/hdxp-manifests/$PKG.txt"

QB=/usr/local/lib/qt6/bin
for pair in qtpaths:qtpaths6 qmake:qmake6; do
    src=${pair%%:*}
    dst=${pair##*:}
    if [ -x "$QB/$src" ]; then $SU ln -sf "$QB/$src" "/usr/local/bin/$dst"; fi
done
sync

for f in lib/libQt6Core.so lib/libQt6Gui.so lib/libQt6Widgets.so lib/libQt6Network.so lib/libQt6DBus.so lib/qt6/plugins/platforms/libqoffscreen.so lib/qt6/plugins/platforms/libqlinuxfb.so; do
    [ -s "/usr/local/$f" ] || { echo "error: /usr/local/$f is empty or missing"; exit 1; }
done
echo "note: Qt6 is installed under /usr/local (tools in /usr/local/lib/qt6/bin, headers in /usr/local/include/qt6), software rendering only"
