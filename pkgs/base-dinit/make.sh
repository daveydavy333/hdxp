SRC="${HDX_SRC:-/hdxp/src/base-dinit-src}"
VER=0.23.0
SHA256=911ed52b78ce4950824623d58826b88a839748e18ef837a234d50db6d83972e2
TARBALL="dinit-$VER.tar.gz"
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-base-dinit}"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/davmac314/dinit/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "dinit-$VER" ] || tar -xf "$TARBALL"
cd "dinit-$VER"
make distclean >/dev/null 2>&1 || true
# dinit-shutdown, dinit-poweroff, dinit-reboot, dinit-halt: the prefix keeps them from
# clashing with situation's and runit's commands, and it is also the name dinit itself runs
# at the end of a system shutdown (/usr/local/sbin/dinit-shutdown).
./configure --prefix=/usr/local --sbindir=/usr/local/sbin --shutdown-prefix=dinit- \
    --disable-capabilities
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
# stage-1 script (the init= target), services and their scripts. these do not touch
# situation: /sbin/init stays as it is, and runit's files are not touched either.
$SU mkdir -p /etc/dinit.d/scripts
$SU install -m 755 "$PORT/dinit-init" /sbin/dinit-init
for s in boot boot-scripts net getty-tty1; do
    $SU install -m 644 "$PORT/svc-$s" "/etc/dinit.d/$s"
done
for s in boot-scripts net getty-tty1; do
    $SU install -m 755 "$PORT/run-$s" "/etc/dinit.d/scripts/$s"
done
# check the installed service descriptions
/usr/local/bin/dinit-check -d /etc/dinit.d boot || echo "warning: dinit-check reported problems"
