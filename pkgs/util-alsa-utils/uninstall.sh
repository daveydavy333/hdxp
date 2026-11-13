# removes what util-alsa-utils installed apart from the /usr/local/bin tools (hdx removes those)
rm -f /usr/local/sbin/alsactl /usr/local/sbin/alsa-info.sh
rm -f /lib/udev/rules.d/90-alsa-restore.rules
rm -rf /usr/local/lib/alsa-topology
echo "note: saved mixer state in /var/lib/alsa is kept"
