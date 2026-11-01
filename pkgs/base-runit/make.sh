SRC="${HDX_SRC:-/hdxp/src/sys-runit-src}"
VER=2.1.2
SHA256=6fd0160cb0cf1207de4e66754b6d39750cff14bb0aa66ab49490992c0c47ba18
TARBALL="runit_$VER.orig.tar.gz"
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-sys-runit}"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/r/runit/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "admin/runit-$VER" ] || tar xzf "$TARBALL"
cd "admin/runit-$VER"
# runit is old C: gcc 14+ turns its pointer-type and implicit-declaration warnings into errors
sed -i 's/short x\[4\]/gid_t x[4]/' src/chkshsgr.c
grep -q 'Wno-error=incompatible' src/conf-cc || \
    sed -i '1s/$/ -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration -Wno-error=int-conversion -Wno-error=implicit-int/' src/conf-cc
package/compile
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
# runit hardcodes /sbin/runit, so the two init binaries go in /sbin
$SU install -m 755 command/runit command/runit-init /sbin/
$SU install -m 755 command/runsv command/runsvdir command/runsvchdir command/sv \
    command/svlogd command/chpst command/utmpset /usr/local/bin/
# stages, services, shutdown commands (these do not touch situation: /sbin/init stays as it is)
$SU mkdir -p /etc/runit/sv/net /etc/runit/sv/getty-tty1 /etc/service /usr/local/sbin
$SU install -m 755 "$PORT/stage1" /etc/runit/1
$SU install -m 755 "$PORT/stage2" /etc/runit/2
$SU install -m 755 "$PORT/stage3" /etc/runit/3
$SU install -m 755 "$PORT/ctrlaltdel" /etc/runit/ctrlaltdel
$SU install -m 755 "$PORT/svc-net-run" /etc/runit/sv/net/run
$SU install -m 755 "$PORT/svc-getty-run" /etc/runit/sv/getty-tty1/run
$SU ln -sfn /etc/runit/sv/net /etc/service/net
$SU ln -sfn /etc/runit/sv/getty-tty1 /etc/service/getty-tty1
for c in poweroff reboot halt; do
    $SU install -m 755 "$PORT/cmd-$c" "/usr/local/sbin/$c"
done
