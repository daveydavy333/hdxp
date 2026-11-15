VER=1.16.2
SHA=0ba2a1a4b16afe7bceb2c07e9ce99a8c2c3508e5dec290dbb643384bd6beb7e2
TAR="dbus-$VER.tar.xz"
SRC="${HDX_SRC:-/hdxp/src/util-dbus-src}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"

# the bus runs as its own user, and the activation helper is setuid root with that group, so both must exist before the install
grep -q '^messagebus:' /etc/group  || $SU addgroup -S messagebus
grep -q '^messagebus:' /etc/passwd || $SU adduser -S -D -H -h /var/empty -s /sbin/nologin -G messagebus -g messagebus messagebus

mkdir -p "$SRC"
cd "$SRC"
if [ ! -f "$TAR" ]; then
    curl -fL -o "$TAR" "https://dbus.freedesktop.org/releases/dbus/$TAR" ||
    curl -fL -o "$TAR" "http://archive.ubuntu.com/ubuntu/pool/main/d/dbus/dbus_$VER.orig.tar.xz"
fi
echo "$SHA  $TAR" | sha256sum -c -
[ -d "dbus-$VER" ] || tar -xf "$TAR"
cd "dbus-$VER"

# no systemd/selinux/apparmor/audit/x11, no docs; the system bus socket lives in /run/dbus
rm -rf build
meson setup build \
    --prefix=/usr/local --sysconfdir=/etc --localstatedir=/var --libdir=lib \
    -Dsystemd=disabled -Dselinux=disabled -Dapparmor=disabled -Dlibaudit=disabled -Dx11_autolaunch=disabled \
    -Dxml_docs=disabled -Ddoxygen_docs=disabled -Dducktype_docs=disabled -Dqt_help=disabled \
    -Dmodular_tests=disabled -Dverbose_mode=false -Dasserts=false \
    -Ddbus_user=messagebus -Dsystem_socket=/run/dbus/system_bus_socket -Dsystem_pid_file=
meson compile -C build
$SU meson install -C build --no-rebuild
$SU rm -rf /usr/local/share/doc/dbus

# boot script (all inits): runtime dir for the socket and the machine id (dbus-uuidgen --ensure only creates it once)
D=/etc/rc.d/boot
TMP="$(mktemp)"
cat > "$TMP" <<'SCRIPT'
# prepare the d-bus system bus (util-dbus)
mkdir -p /run/dbus /var/lib/dbus
[ -s /etc/machine-id ] || dbus-uuidgen --ensure=/etc/machine-id >/dev/null 2>&1
ln -sf /etc/machine-id /var/lib/dbus/machine-id
true
SCRIPT
$SU mkdir -p "$D"
$SU cp "$TMP" "$D/12-dbus.sh"
$SU chmod 755 "$D/12-dbus.sh"

# runit service (only if this install has /etc/service)
if [ -d /etc/service ]; then
    cat > "$TMP" <<'SCRIPT'
#!/bin/sh
exec 2>&1
mkdir -p /run/dbus
exec /usr/local/bin/dbus-daemon --system --nofork --nopidfile
SCRIPT
    $SU mkdir -p /etc/service/dbus
    $SU cp "$TMP" /etc/service/dbus/run
    $SU chmod 755 /etc/service/dbus/run
fi

# dinit service (only if this install has /etc/dinit.d); it needs the boot scripts first when that service exists
if [ -d /etc/dinit.d ]; then
    {
        echo "type = process"
        echo "command = /usr/local/bin/dbus-daemon --system --nofork --nopidfile"
        echo "restart = true"
        [ -e /etc/dinit.d/boot-scripts ] && echo "depends-on = boot-scripts"
    } > "$TMP"
    $SU cp "$TMP" /etc/dinit.d/dbus
    echo "note: to start dbus at boot under dinit add this line to /etc/dinit.d/boot:  waits-for = dbus"
fi
rm -f "$TMP"
sync

for f in /usr/local/bin/dbus-daemon /usr/local/bin/dbus-uuidgen /usr/local/libexec/dbus-daemon-launch-helper /etc/dbus-1/system.conf /etc/rc.d/boot/12-dbus.sh; do
    [ -s "$f" ] || { echo "error: $f is empty or missing"; exit 1; }
done
[ -u /usr/local/libexec/dbus-daemon-launch-helper ] || echo "note: dbus-daemon-launch-helper is not setuid, run: chown root:messagebus it && chmod 4750 it"
echo "note: situation has no service here yet: start the bus by hand with: dbus-daemon --system"
echo "note: start a desktop with its own session bus, e.g.: dbus-run-session sway"
