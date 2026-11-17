#!/bin/sh
# OpenRC 0.64.1 as an extra init (init=/sbin/openrc-stage1). Does not touch /sbin/init.
set -eu
NAME=base-openrc
VER=0.64.1
SHA=56d6d24c7fd2ca15d1abd1fb82ce5430629a71acb2c3fa12760300243dbd0baa
URL="https://github.com/OpenRC/openrc/archive/refs/tags/$VER.tar.gz"
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-$NAME}"
SRC="${HDX_SRC:-/hdxp/src/$NAME-src}"
[ "$(id -u)" = 0 ] && SU= || SU=doas
export PATH="/usr/local/sbin:/usr/local/bin:$PATH"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

for f in stage1 svc-hdx-boot svc-hdx-shutdown svc-dbus svc-iwd svc-net svc-getty-tty1 run-net cmd-poweroff cmd-reboot cmd-halt; do
	[ -f "$PORT/$f" ] || { echo "missing $PORT/$f" >&2; exit 1; }
done

mkdir -p "$SRC"; cd "$SRC"
[ -f "openrc-$VER.tar.gz" ] || curl -fL -o "openrc-$VER.tar.gz" "$URL"
echo "$SHA  openrc-$VER.tar.gz" | sha256sum -c -
rm -rf "openrc-$VER"; tar xf "openrc-$VER.tar.gz"; cd "openrc-$VER"

meson setup build --prefix=/usr/local --sysconfdir=/etc --libdir=lib \
	--libexecdir=/usr/local/libexec --sbindir=/usr/local/sbin \
	-Dpam=false -Dselinux=disabled -Daudit=disabled -Dnewnet=false \
	-Dsysvinit=false -Dshell=/bin/sh -Duucp_group=root -Dpkgconfig=false
meson compile -C build
$SU meson install -C build

# openrc-init resets PATH to /sbin:/usr/sbin:/bin:/usr/bin, so link the tools into /sbin
for b in openrc openrc-init openrc-run openrc-shutdown rc rc-service rc-update rc-status rc-sstat rc-depend \
         start-stop-daemon supervise-daemon mountinfo fstabinfo checkpath; do
	for d in /usr/local/sbin /usr/local/bin; do
		if [ -x "$d/$b" ]; then $SU ln -sf "$d/$b" "/sbin/$b"; break; fi
	done
done

# our services and helpers
$SU mkdir -p /usr/local/libexec/hdx /var/log
for s in hdx-boot hdx-shutdown dbus iwd net getty-tty1; do
	$SU install -m755 "$PORT/svc-$s" "/etc/init.d/$s"
done
$SU install -m755 "$PORT/run-net" /usr/local/libexec/hdx/openrc-net
$SU install -m755 "$PORT/stage1" /sbin/openrc-stage1
for c in poweroff reboot halt; do
	$SU install -m755 "$PORT/cmd-$c" "/usr/local/sbin/openrc-$c"
done

# poweroff/reboot/halt wrappers: dispatch to openrc when PID 1 is openrc-init
for c in poweroff reboot halt; do
	w=/usr/local/sbin/$c
	LINE='[ "$(cat /proc/1/comm 2>/dev/null)" = openrc-init ] && exec /usr/local/sbin/openrc-'$c' "$@"'
	if [ -f "$w" ]; then
		grep -q openrc-init "$w" || $SU sed -i "1a\\
$LINE" "$w"
	else
		printf '#!/bin/sh\n%s\nexec busybox %s "$@"\n' "$LINE" "$c" > "/tmp/hdx-$c.$$"
		$SU install -m755 "/tmp/hdx-$c.$$" "$w"; rm -f "/tmp/hdx-$c.$$"
	fi
done

# minimal runlevels (the default ones need keymaps, hwclock, seedrng, ... that fail on busybox)
$SU find /etc/runlevels -mindepth 2 -type l -exec rm -f {} + 2>/dev/null || true
add() { l=$1; shift; $SU mkdir -p "/etc/runlevels/$l"; for s in "$@"; do $SU ln -sf "/etc/init.d/$s" "/etc/runlevels/$l/$s"; done; }
DEF=
command -v dbus-daemon >/dev/null 2>&1 && DEF="dbus"
if [ -x /usr/local/libexec/iwd ] || [ -x /usr/libexec/iwd ] || command -v iwd >/dev/null 2>&1; then DEF="$DEF iwd"; fi
add sysinit
add boot hdx-boot
add default $DEF net getty-tty1
add shutdown hdx-shutdown mount-ro
sync
echo "base-openrc $VER installed. Boot it with init=/sbin/openrc-stage1 on the kernel command line."
echo "default runlevel: $DEF net getty-tty1"
