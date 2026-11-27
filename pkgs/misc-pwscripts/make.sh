# glue for running PipeWire without systemd/logind: one launcher script plus a service per init that is installed here
# (OpenRC, and runit/dinit when their directories exist) and the ALSA default-device link. services are installed but NOT enabled
SRC="${HDX_SRC:-/hdxp/src/misc-pwscripts-src}"
PKG="${HDX_PKG:-misc-pwscripts}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

for f in /usr/local/bin/pipewire /usr/local/bin/wireplumber /usr/local/bin/pipewire-pulse; do
    [ -x "$f" ] || { echo "error: $f missing, install devel-pipewire and devel-wireplumber first"; exit 1; }
done

F="$SRC/files"
LIST="$SRC/manifest.txt"
rm -rf "$F"
mkdir -p "$F"
: > "$LIST"
put() { # mode source destination
    $SU install -Dm"$1" "$2" "$3"
    echo "$3" >> "$LIST"
}

# ---- launcher: sets the environment every pipewire daemon needs and waits for the pipewire socket
cat > "$F/hdx-pw-run" <<'WRAP'
#!/bin/sh
# runs one PipeWire daemon: hdx-pw-run pipewire | wireplumber | pipewire-pulse
# XDG_RUNTIME_DIR must be the same one your shell and your programs use; override it in /etc/hdx-pipewire.conf
[ -f /etc/hdx-pipewire.conf ] && . /etc/hdx-pipewire.conf
: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
: "${HOME:=/root}"
export XDG_RUNTIME_DIR HOME
export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 0700 "$XDG_RUNTIME_DIR"

wait_for_socket() {
    n=0
    while [ ! -S "$XDG_RUNTIME_DIR/pipewire-0" ] && [ "$n" -lt 100 ]; do
        sleep 0.1
        n=$((n + 1))
    done
}

case "$1" in
    pipewire) exec /usr/local/bin/pipewire ;;
    wireplumber) wait_for_socket; exec /usr/local/bin/wireplumber ;;
    pipewire-pulse) wait_for_socket; exec /usr/local/bin/pipewire-pulse ;;
    *) echo "usage: hdx-pw-run pipewire|wireplumber|pipewire-pulse" >&2; exit 1 ;;
esac
WRAP
put 755 "$F/hdx-pw-run" /usr/local/libexec/hdx-pw-run

# alsa-lib only reads snippets from /etc/alsa/conf.d (not from its datadir), so link pipewire's two there:
# this is what makes the ALSA "default" device go through PipeWire
for c in 50-pipewire.conf 99-pipewire-default.conf; do
    if [ -f "/usr/local/share/alsa/alsa.conf.d/$c" ]; then
        $SU mkdir -p /etc/alsa/conf.d
        $SU ln -sf "/usr/local/share/alsa/alsa.conf.d/$c" "/etc/alsa/conf.d/$c"
        echo "/etc/alsa/conf.d/$c" >> "$LIST"
    fi
done

# default config, never overwritten and not removed on uninstall (you may edit it)
if [ ! -e /etc/hdx-pipewire.conf ]; then
    cat > "$F/hdx-pipewire.conf" <<'CONF'
# read by /usr/local/libexec/hdx-pw-run (sh syntax). XDG_RUNTIME_DIR must match the one in your login shell
# (check with: echo $XDG_RUNTIME_DIR), otherwise programs cannot find the pipewire socket
#XDG_RUNTIME_DIR=/run/user/0
CONF
    $SU install -Dm644 "$F/hdx-pipewire.conf" /etc/hdx-pipewire.conf
fi

# ---- OpenRC
if [ -d /etc/init.d ] && [ -x /usr/local/sbin/openrc-run ]; then
    mk_openrc() { # name description depend-lines
        cat > "$F/openrc-$1" <<SVC
#!/usr/local/sbin/openrc-run
description="$2"
supervisor=supervise-daemon
command=/usr/local/libexec/hdx-pw-run
command_args="$1"
respawn_delay=2
respawn_max=5
respawn_period=60
output_log=/var/log/pipewire.log
error_log=/var/log/pipewire.log

depend() {
$3
}
SVC
        put 755 "$F/openrc-$1" "/etc/init.d/$1"
    }
    mk_openrc pipewire "PipeWire media server" "	need localmount
	use dbus
	after hdx-boot"
    mk_openrc wireplumber "WirePlumber session manager for PipeWire" "	need pipewire"
    mk_openrc pipewire-pulse "PipeWire PulseAudio server" "	need pipewire
	after wireplumber"
fi

# ---- runit (services start as soon as they are linked into /etc/service)
if [ -d /etc/service ]; then
    for s in pipewire wireplumber pipewire-pulse; do
        printf '#!/bin/sh\nexec 2>&1\nexec /usr/local/libexec/hdx-pw-run %s\n' "$s" > "$F/runit-$s"
        put 755 "$F/runit-$s" "/etc/service/$s/run"
    done
fi

# ---- dinit (add `waits-for = pipewire` etc. to /etc/dinit.d/boot to start them at boot)
if [ -d /etc/dinit.d ]; then
    mk_dinit() { # name depends-on
        printf 'type = process\ncommand = /usr/local/libexec/hdx-pw-run %s\nlogfile = /var/log/pipewire.log\nrestart = true\ndepends-on = %s\n' "$1" "$2" > "$F/dinit-$1"
        put 644 "$F/dinit-$1" "/etc/dinit.d/$1"
    }
    mk_dinit pipewire boot-scripts
    mk_dinit wireplumber pipewire
    mk_dinit pipewire-pulse pipewire
fi

$SU install -Dm644 "$LIST" "/usr/local/share/hdxp-manifests/$PKG.txt"
sync

[ -x /usr/local/libexec/hdx-pw-run ] || { echo "error: /usr/local/libexec/hdx-pw-run is missing"; exit 1; }
echo "note: services are installed but not enabled. OpenRC: rc-update add pipewire default; rc-update add wireplumber default; rc-update add pipewire-pulse default"
