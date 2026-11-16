VER=3.10
SHA=640bff22540e1714f71772a83123aff6f810b7eb9d7d6df1e10fb2695beb5115
TAR="iwd-$VER.tar.xz"
SRC="${HDX_SRC:-/hdxp/src/util-iwd-src}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

# iwd needs a lot of kernel crypto (AF_ALG, keyrings, x509/pkcs) and the kernel has no initramfs and no modules,
# so it has to be built in: rebuild base-kernel (hdx i -f base-kernel) from a make.sh that has the iwd options first.
KERNEL_OK=1
if [ -r "/boot/config-6.18.55" ]; then
    for o in KEYS CRYPTO_USER_API_HASH CRYPTO_USER_API_SKCIPHER KEY_DH_OPERATIONS PKCS8_PRIVATE_KEY_PARSER; do
        grep -q "^CONFIG_$o=y" /boot/config-6.18.55 || { KERNEL_OK=0; echo "note: CONFIG_$o is not enabled in /boot/config-6.18.55, iwd will not start until base-kernel is rebuilt with the iwd options"; }
    done
fi

mkdir -p "$SRC"
cd "$SRC"
if [ ! -f "$TAR" ]; then
    curl -fL -o "$TAR" "https://cdn.kernel.org/pub/linux/network/wireless/$TAR" ||
    curl -fL -o "$TAR" "http://archive.ubuntu.com/ubuntu/pool/universe/i/iwd/iwd_$VER.orig.tar.xz"
fi
echo "$SHA  $TAR" | sha256sum -c -
[ -d "iwd-$VER" ] || tar -xf "$TAR"
cd "iwd-$VER"

# the tarball carries its own copy of ell, which gets linked into iwd (no separate ell port needed);
# the d-bus policy goes to /usr/local/share/dbus-1/system.d where the bus looks for it;
# dhcp is left to the init's net service (iwd only handles the wifi connection)
./configure --prefix=/usr/local --sysconfdir=/etc --localstatedir=/var --libdir=/usr/local/lib \
    --disable-systemd-service --disable-manual-pages --with-dbus-datadir=/usr/local/share
make -j"$(nproc)"
$SU make install
$SU mkdir -p /var/lib/iwd /var/log
$SU chmod 700 /var/lib/iwd

TMP="$(mktemp)"
# runit service (only if this install has /etc/service): wait for the bus, keep iwd's output off the console
if [ -d /etc/service ]; then
    cat > "$TMP" <<'SCRIPT'
#!/bin/sh
sv -w 20 start /etc/service/dbus >/dev/null 2>&1
exec /usr/local/libexec/iwd >>/var/log/iwd.log 2>&1
SCRIPT
    $SU mkdir -p /etc/service/iwd
    $SU cp "$TMP" /etc/service/iwd/run
    $SU chmod 755 /etc/service/iwd/run
    # if iwd quits (no bus, missing kernel options) wait before runit restarts it
    printf '#!/bin/sh\nsleep 15\n' > "$TMP"
    $SU cp "$TMP" /etc/service/iwd/finish
    $SU chmod 755 /etc/service/iwd/finish
    if [ "$KERNEL_OK" -eq 0 ]; then
        $SU touch /etc/service/iwd/down
        echo "note: the iwd service is kept down until the kernel is rebuilt; afterwards: rm /etc/service/iwd/down; sv up iwd"
    else
        $SU rm -f /etc/service/iwd/down
    fi
fi
# dinit service (only if this install has /etc/dinit.d)
if [ -d /etc/dinit.d ]; then
    {
        echo "type = process"
        echo "command = /usr/local/libexec/iwd"
        echo "restart = true"
        echo "restart-delay = 15"
        echo "restart-limit-count = 5"
        echo "log-type = file"
        echo "logfile = /var/log/iwd.log"
        [ -e /etc/dinit.d/dbus ] && echo "depends-on = dbus"
    } > "$TMP"
    $SU cp "$TMP" /etc/dinit.d/iwd
    echo "note: to start iwd at boot under dinit add this line to /etc/dinit.d/boot:  waits-for = iwd"
fi
rm -f "$TMP"
sync

for f in /usr/local/libexec/iwd /usr/local/bin/iwctl /usr/local/share/dbus-1/system.d/iwd-dbus.conf; do
    [ -s "$f" ] || { echo "error: $f is empty or missing"; exit 1; }
done
echo "note: stop wpa_supplicant before using iwd (both want wlan0); connect with: iwctl station wlan0 connect SSID"
echo "note: situation has no iwd service here yet: start it by hand with: /usr/local/libexec/iwd &"
