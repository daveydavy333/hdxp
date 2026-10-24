SRC="${HDX_SRC:-/hdxp/src/util-wpa_supplicant-src}"
VER=2.11
SHA256=REPLACE_ME
TARBALL="wpa_supplicant-$VER.tar.gz"
if [ "$SHA256" = REPLACE_ME ]; then
    echo "util-wpa_supplicant: pin SHA256 in make.sh first (sha256sum of $TARBALL)" >&2
    exit 1
fi
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://w1.fi/releases/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "wpa_supplicant-$VER" ] || tar xzf "$TARBALL"
cd "wpa_supplicant-$VER/wpa_supplicant"
cat > .config <<'EOF'
CONFIG_DRIVER_NL80211=y
CONFIG_LIBNL32=y
CONFIG_CTRL_IFACE=y
CONFIG_BACKEND=file
CONFIG_TLS=internal
CONFIG_INTERNAL_LIBTOMMATH=y
CONFIG_IEEE80211W=y
CONFIG_IEEE80211N=y
CONFIG_IEEE80211AC=y
CFLAGS += -I/usr/local/include/libnl3
LDFLAGS += -L/usr/local/lib
EOF
make -j"$(nproc 2>/dev/null || echo 1)" PKG_CONFIG=true
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install BINDIR=/usr/local/bin
