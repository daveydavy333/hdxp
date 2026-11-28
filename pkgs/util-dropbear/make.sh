SRC="${HDX_SRC:-/hdxp/src/util-dropbear-src}"
PKG="${HDX_PKG:-util-dropbear}"
VER=2026.94
SHA256=827d3f6e510e7554ee18d5c6a00dfee1a6a555559495e65e2e8f8d41c79eed84
TARBALL="dropbear-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/mkj/dropbear/archive/refs/tags/DROPBEAR_$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "dropbear-DROPBEAR_$VER" ] || tar xf "$TARBALL"
cd "dropbear-DROPBEAR_$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
# logged-in users (root too) get a PATH that includes /usr/local (dropbear's defaults leave it out)
cat > localoptions.h <<'OPT'
#define DEFAULT_PATH "/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
#define DEFAULT_ROOT_PATH "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
OPT
./configure --prefix=/usr/local --disable-pam
PROGS="dropbear dbclient dropbearkey dropbearconvert scp"
make -j"$(nproc 2>/dev/null || echo 1)" PROGRAMS="$PROGS"
STAGE="$SRC/stage"
rm -rf "$STAGE"
make install PROGRAMS="$PROGS" DESTDIR="$STAGE"
# the server goes in /usr/local/bin with the rest (hdx only looks for binaries in bin directories)
mv "$STAGE/usr/local/sbin/dropbear" "$STAGE/usr/local/bin/dropbear"
rmdir "$STAGE/usr/local/sbin" 2>/dev/null || true
# ssh and scp's remote program name: link ssh to dbclient unless something else owns that name
if [ ! -e /usr/local/bin/ssh ] || [ "$(readlink /usr/local/bin/ssh)" = dbclient ]; then
    ln -sf dbclient "$STAGE/usr/local/bin/ssh"
else
    echo "util-dropbear: /usr/local/bin/ssh already exists, not replacing it"
fi

# ---- services: installed but NOT enabled (an ssh server should never start by surprise)
ARGS="-F -R -E -p 22"
if [ -d /etc/init.d ] && [ -x /usr/local/sbin/openrc-run ]; then
    mkdir -p "$STAGE/etc/init.d"
    cat > "$STAGE/etc/init.d/dropbear" <<SVC
#!/usr/local/sbin/openrc-run
description="Dropbear SSH server"
supervisor=supervise-daemon
command=/usr/local/bin/dropbear
command_args="$ARGS"
respawn_delay=2
respawn_max=5
respawn_period=60
output_log=/var/log/dropbear.log
error_log=/var/log/dropbear.log

depend() {
	need localmount
	use net
}
SVC
    chmod 755 "$STAGE/etc/init.d/dropbear"
fi
RUNIT_DIR=
if [ -d /etc/runit/sv ]; then RUNIT_DIR=/etc/runit/sv; elif [ -d /etc/service ]; then RUNIT_DIR=/etc/service; fi
if [ -n "$RUNIT_DIR" ]; then
    mkdir -p "$STAGE$RUNIT_DIR/dropbear"
    printf '#!/bin/sh\nexec 2>&1\nexec /usr/local/bin/dropbear %s\n' "$ARGS" > "$STAGE$RUNIT_DIR/dropbear/run"
    chmod 755 "$STAGE$RUNIT_DIR/dropbear/run"
    # a "down" file keeps runit from starting it the moment it is linked into /etc/service
    if [ "$RUNIT_DIR" = /etc/service ]; then : > "$STAGE$RUNIT_DIR/dropbear/down"; fi
fi
if [ -d /etc/dinit.d ]; then
    mkdir -p "$STAGE/etc/dinit.d"
    printf 'type = process\ncommand = /usr/local/bin/dropbear %s\nlogfile = /var/log/dropbear.log\nrestart = true\ndepends-on = boot-scripts\n' "$ARGS" > "$STAGE/etc/dinit.d/dropbear"
    chmod 644 "$STAGE/etc/dinit.d/dropbear"
fi

( cd "$STAGE" && find . \( -type f -o -type l \) | sed 's|^\.||' ) > "$SRC/manifest.txt"
$SU cp -R "$STAGE"/. /
$SU install -Dm644 "$SRC/manifest.txt" "/usr/local/share/hdxp-manifests/$PKG.txt"
$SU mkdir -p /etc/dropbear
$SU chmod 700 /etc/dropbear

# dropbear only lets users in whose login shell is listed in /etc/shells
if [ ! -f /etc/shells ]; then
    : > "$SRC/shells"
    for s in /bin/sh /bin/ash /bin/bash /bin/zsh /usr/local/bin/zsh /usr/local/bin/oksh; do
        if [ -x "$s" ]; then echo "$s" >> "$SRC/shells"; fi
    done
    $SU install -Dm644 "$SRC/shells" /etc/shells
fi
sync
[ -x /usr/local/bin/dropbear ]
echo "util-dropbear: host keys are created on the first connection (-R). log in with a key (~/.ssh/authorized_keys, mode 600, ~ not group-writable) or a password set with passwd"
echo "util-dropbear: OpenRC: rc-service dropbear start (rc-update add dropbear default). runit: ln -s /etc/runit/sv/dropbear /etc/service/ (or rm /etc/service/dropbear/down). dinit: dinitctl start dropbear"
