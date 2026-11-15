# audio boot scripts: restores the saved alsa mixer state at boot (needs util-alsa-utils for alsactl/amixer)
command -v alsactl >/dev/null || { echo "error: alsactl not found (hdx i util-alsa-utils first)"; exit 1; }
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
D=/etc/rc.d/boot
TMP="$(mktemp)"

cat > "$TMP" <<'SCRIPT'
# restore the saved alsa mixer state (misc-ascripts)
# alsactl keeps its lock in /var/lock -> ../run/lock, and /run is a tmpfs, so it has to be made on every boot.
# done here (after 05-mount.sh has mounted /run) so the order can't go wrong.
mkdir -p /run/lock /var/lib/alsa
if [ -s /var/lib/alsa/asound.state ]; then
    alsactl restore >/dev/null 2>&1
else
    # first boot, nothing saved yet: init the card and unmute what exists (store a state with: alsactl store)
    alsactl init >/dev/null 2>&1
    for c in Master Speaker Headphone; do amixer -q sset "$c" unmute >/dev/null 2>&1; done
fi
true
SCRIPT

$SU mkdir -p "$D" /var/lib/alsa /run/lock
$SU rm -f "$D/02-runlock.sh"
$SU cp "$TMP" "$D/11-alsa.sh"
$SU chmod 755 "$D/11-alsa.sh"
rm -f "$TMP"
[ -s "$D/11-alsa.sh" ] || { echo "error: $D/11-alsa.sh is empty or missing"; exit 1; }
sync
echo "installed $D/11-alsa.sh (store your mixer state with: alsactl store)"
