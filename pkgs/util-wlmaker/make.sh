#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-util-wlmaker}"
SRC="${HDX_SRC:-/hdxp/src/util-wlmaker-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() {
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "util-wlmaker: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
fetch() {
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "util-wlmaker: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}
mkdir -p "$SRC"
cd "$SRC"

VER=0.8.1
LIBBASE=54e60555cae53ad99314c7579dce1ad38373ecaa
INIH=26254ee9de7681f8825433415443e7116ff24b98
fetch "https://github.com/phkaeser/wlmaker/archive/refs/tags/v$VER.tar.gz" \
    "wlmaker-$VER.tar.gz" c009653de70bdb28b5f18d97e748d79a2f580760e964cf57820cb053c843024d
fetch "https://github.com/phkaeser/libbase/archive/$LIBBASE.tar.gz" \
    "libbase-$LIBBASE.tar.gz" b4b220294d8fa1311b9c0d693f20a0a6d3fe546ca5de1934d91183d70e118d8b
fetch "https://github.com/benhoyt/inih/archive/$INIH.tar.gz" \
    "inih-$INIH.tar.gz" c74d39d84755c54a1a546a282b3cfe12dace521c68ea4342f8582c961aff6fd0

need wlroots-0.20 0.20
need wayland-server 1.22.0
need wayland-client 1.22.0
need wayland-protocols 1.32
need cairo 1.16.0
need xkbcommon 1.5.0
need libxdg-basedir 1.2
need libinput 0

# musl has no fts: use devel-musl-fts
FTS_H=$(find /usr /opt -name fts.h 2>/dev/null | head -1)
[ -n "$FTS_H" ] || { echo "util-wlmaker: fts.h not found, hdx i devel-musl-fts first" >&2; exit 1; }
FTS_INC=$(dirname "$FTS_H")
export CPATH="$FTS_INC${CPATH:+:$CPATH}"
export LIBRARY_PATH="$(dirname "$FTS_INC")/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"

rm -rf "wlmaker-$VER"
mkdir "wlmaker-$VER"
tar xzf "wlmaker-$VER.tar.gz" -C "wlmaker-$VER" --strip-components=1
cd "wlmaker-$VER"

rm -rf submodules/libbase submodules/inih
mkdir -p submodules/libbase submodules/inih
tar xzf "../libbase-$LIBBASE.tar.gz" -C submodules/libbase --strip-components=1
tar xzf "../inih-$INIH.tar.gz" -C submodules/inih --strip-components=1

# this wlroots has no x11 backend: drop the header and the x11 output checks
sed -i '/x11\.h/d' src/backend/output.c
sed -i 's/wlr_output_is_x11(wlr_output_ptr)/0/g' src/backend/output.c
# launchers/menu hardcode /usr/bin/: hdxp installs to /usr/local/bin, use PATH lookup instead
sed -i "s|/usr/bin/||g" etc/State.plist etc/RootMenu.plist etc/Config.plist
if grep -q 'wlr_output_is_x11\|x11\.h' src/backend/output.c; then
    echo "util-wlmaker: x11 patch did not apply" >&2; exit 1
fi

# xcb is only needed for XWayland (off): make it optional; skip the tests
sed -i 's/pkg_check_modules(XCB REQUIRED IMPORTED_TARGET xcb>=1.15)/pkg_check_modules(XCB IMPORTED_TARGET xcb>=1.15)/' src/CMakeLists.txt
sed -i 's/^  PkgConfig::XCB)$/  )/' src/CMakeLists.txt
sed -i '/^add_subdirectory(tests)$/d' CMakeLists.txt
grep -q 'IMPORTED_TARGET xcb>=1.15)' src/CMakeLists.txt && ! grep -q 'PkgConfig::XCB' src/CMakeLists.txt \
    || { echo "util-wlmaker: xcb patch did not apply" >&2; exit 1; }

cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_INSTALL_SYSCONFDIR=/etc \
    -DCMAKE_C_STANDARD_LIBRARIES=-lfts \
    -Dconfig_DEBUG=OFF -Dconfig_OPTIM=ON \
    -DBUILD_TESTING=OFF
cmake --build build -j "$JOBS"
$SU cmake --install build
sync
