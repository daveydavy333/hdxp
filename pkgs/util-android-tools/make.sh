VER=37.0.0p1
SHA=2c6de1abe16b211c7d9f59276217e14fd9e0e18b20e331d3c84358f5dffd576e
TAR="android-tools-$VER.tar.xz"
SRC="${HDX_SRC:-/hdxp/src/util-android-tools-src}"
PKG="${HDX_PKG:-util-android-tools}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"
command -v cmake >/dev/null || { echo "error: cmake not found (devel-cmake)"; exit 1; }
command -v xz >/dev/null || command -v unxz >/dev/null || { echo "error: neither xz nor unxz found, the release tarball is .tar.xz"; exit 1; }
for m in libusb-1.0 libbrotlidec liblz4 libzstd libpcre2-8; do
    pkg-config --exists "$m" || { echo "error: pkg-config module '$m' not found"; exit 1; }
done
JOBS=$(nproc 2>/dev/null || echo 1)

# the nmeum release tarball already contains the patched vendored AOSP sources (adb, fastboot, boringssl,
# e2fsprogs, f2fs-tools, ...), so nothing is cloned and no patches are applied
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://github.com/nmeum/android-tools/releases/download/$VER/$TAR"
echo "$SHA  $TAR" | sha256sum -c -
if [ ! -d "android-tools-$VER" ]; then
    if command -v xz >/dev/null; then xz -dc "$TAR" | tar -x; else unxz -c "$TAR" | tar -x; fi
fi
cd "android-tools-$VER"

# a failed build is resumed, not restarted: rm -rf build to force a reconfigure
# no mDNS (that part is Rust), system libusb/fmt/brotli/lz4/zstd/pcre2/protobuf, everything else static
if [ ! -f build/CMakeCache.txt ]; then
    rm -rf build
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_SHARED_LIBS=OFF -DANDROID_TOOLS_PATCH_VENDOR=OFF \
        -DANDROID_TOOLS_ADB_ENABLE_MDNS=OFF
fi
cmake --build build --parallel "$JOBS"
$SU cmake --install build
[ -s build/install_manifest.txt ] || { echo "error: no install manifest"; exit 1; }
$SU install -Dm644 build/install_manifest.txt "/usr/local/share/hdxp-manifests/$PKG.txt"

# udev rules so adb and fastboot work without root; the marker on the first line is what uninstall.sh checks
RULES=/etc/udev/rules.d/51-android.rules
TMP="$SRC/51-android.rules"
cat > "$TMP" <<'RULES'
# installed by hdxp util-android-tools: any local user may talk to these Android devices (adb and fastboot)
# Google
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666"
# Xiaomi
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0666"
# MediaTek (preloader / BROM)
SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", MODE="0666"
# Qualcomm (EDL)
SUBSYSTEM=="usb", ATTR{idVendor}=="05c6", MODE="0666"
# Samsung
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666"
# Motorola
SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", MODE="0666"
# OnePlus
SUBSYSTEM=="usb", ATTR{idVendor}=="2a70", MODE="0666"
# Sony
SUBSYSTEM=="usb", ATTR{idVendor}=="0fce", MODE="0666"
# Huawei
SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", MODE="0666"
# ASUS
SUBSYSTEM=="usb", ATTR{idVendor}=="0b05", MODE="0666"
# Lenovo
SUBSYSTEM=="usb", ATTR{idVendor}=="17ef", MODE="0666"
RULES
if [ -f "$RULES" ] && ! head -n1 "$RULES" | grep -q 'installed by hdxp util-android-tools'; then
    echo "note: $RULES exists and is not ours, left alone"
else
    $SU install -Dm644 "$TMP" "$RULES"
    if command -v udevadm >/dev/null; then $SU udevadm control --reload-rules || true; fi
fi
sync

for f in bin/adb bin/fastboot bin/mke2fs.android bin/simg2img; do
    [ -s "/usr/local/$f" ] || { echo "error: /usr/local/$f is empty or missing"; exit 1; }
done
/usr/local/bin/adb version
/usr/local/bin/fastboot --version
echo "note: avbtool, mkbootimg, unpack_bootimg and friends are python3 scripts and need devel-python3 at run time"
