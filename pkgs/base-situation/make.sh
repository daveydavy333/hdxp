SRC="${HDX_SRC:-/hdxp/src/base-situation-src}"
[ -d "$SRC/.git" ] || git clone https://codeberg.org/derivelinux/situation "$SRC"
# pinned to the commit tested in the first hdxi boot
git -C "$SRC" checkout -q ec064d44f0d819f8523633851abc9b547bff6eb1
cd "$SRC"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU sh ./install.sh
# install.sh makes absolute //bin/... links; initramfs checks need relative ones
$SU ln -sf ../bin/situation /sbin/init
$SU ln -sf situation /bin/init
# situation's own reboot/poweroff/halt live in /bin. busybox's links in /sbin signal
# pid 1 differently, so remove them if they are still busybox links
for c in reboot halt poweroff; do
    if [ -L "/sbin/$c" ]; then
        case "$(readlink -f "/sbin/$c" 2>/dev/null)" in */busybox*) $SU rm -f "/sbin/$c" ;; esac
    fi
done
# default service: dhcp on the first interface, enabled at boot
$SU mkdir -p /etc/sv/on
cat > "$SRC/net.sv" <<'EOF_NET'
#!/bin/sh
# dhcp on the first physical ethernet-style interface that has a link.
# lo and virtual devices (sit0, tunnels, bridges) have no "device" entry,
# so they are skipped. waits until a link shows up (cable, usb tether, ...).
NETDIR="${NETDIR:-/sys/class/net}"
while :; do
    for d in "$NETDIR"/*; do
        [ -e "$d/device" ] || continue
        [ "$(cat "$d/type" 2>/dev/null)" = 1 ] || continue
        n=${d##*/}
        ip link set "$n" up 2>/dev/null
        [ "$(cat "$d/carrier" 2>/dev/null)" = 1 ] && break 2
    done
    sleep 2
done

# mark ready once a default route exists
( until ip route | grep -q '^default'; do sleep 1; done
  touch /run/sv/ready/net ) &

# dhcp client output goes to a log, not the console
exec udhcpc -f -i "$n" >/var/log/net.log 2>&1
EOF_NET
[ -s "$SRC/net.sv" ] || { echo "net service came out empty"; exit 1; }
$SU install -m 755 "$SRC/net.sv" /etc/sv/net
$SU ln -sf /etc/sv/net /etc/sv/on/net
sync
