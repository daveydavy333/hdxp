set -e
SRC="${HDX_SRC:-/hdxp/src/util-brightnessctl-src}"
VER=0.5.1
SHA256=a68869e23f56ac4f2e28f1783002810ddbf10f95e1af9b48b2912fb169f46994
TARBALL="brightnessctl-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/Hummer12007/brightnessctl/archive/refs/tags/$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "brightnessctl-$VER" ] || tar -xf "$TARBALL"
cd "brightnessctl-$VER"
make clean >/dev/null 2>&1 || true
make PREFIX=/usr/local
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
# installs the binary (not setuid) and a udev rule that makes the backlight and leds
# writable for the video and input groups; root can always use it
$SU make install PREFIX=/usr/local
