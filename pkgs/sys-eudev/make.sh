SRC="${HDX_SRC:-/hdxp/src/sys-eudev-src}"
VER=3.2.14
SHA256=8da4319102f24abbf7fff5ce9c416af848df163b29590e666d334cc1927f006f
TARBALL="eudev-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/eudev-project/eudev/releases/download/v$VER/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "eudev-$VER" ] || tar xzf "$TARBALL"
cd "eudev-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
# rules and helpers land in /usr/local/lib/udev, local rules go in /etc/udev/rules.d
./configure --prefix=/usr/local --sysconfdir=/etc \
    --disable-manpages --disable-selinux --disable-kmod --disable-blkid \
    --disable-mtd_probe --enable-hwdb
make -j"$(nproc 2>/dev/null || echo 1)"
$SU make install
$SU mkdir -p /etc/udev/rules.d /etc/rc.d/boot
$SU /usr/local/bin/udevadm hwdb --update || true
# start udev at boot, before the other boot scripts that need device nodes.
# the script is written from here (not copied from the port folder), so there is no second file to lose
BOOT="$SRC/03-udev.sh"
cat > "$BOOT" <<'EOF_UDEV'
#!/bin/sh
# 03-udev.sh - start eudev: daemon, coldplug the devices already present, wait for the nodes
UDEVD=/usr/local/sbin/udevd
UDEVADM=/usr/local/bin/udevadm
[ -x "$UDEVD" ] && [ -x "$UDEVADM" ] || { echo "udev: not installed, skipping"; exit 0; }
mkdir -p /run/udev
# no hotplug helper: udevd listens for kernel events itself
[ -w /proc/sys/kernel/hotplug ] && echo "" > /proc/sys/kernel/hotplug
"$UDEVD" --daemon
"$UDEVADM" trigger --type=subsystems --action=add
"$UDEVADM" trigger --type=devices --action=add
"$UDEVADM" settle --timeout=10
:
EOF_UDEV
[ -s "$BOOT" ] || { echo "03-udev.sh came out empty"; exit 1; }
$SU install -m 755 "$BOOT" /etc/rc.d/boot/03-udev.sh
[ -s /usr/local/sbin/udevd ] && [ -s /usr/local/bin/udevadm ] && [ -s /etc/rc.d/boot/03-udev.sh ] \
    || { echo "sys-eudev: an installed file is empty"; exit 1; }
sync
