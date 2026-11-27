# removes exactly what make.sh installed, using the install manifest it saved
[ -n "$HDX_PKG" ] || { echo "HDX_PKG is empty, refusing to continue"; exit 1; }
M="/usr/local/share/hdxp-manifests/$HDX_PKG.txt"
[ -f "$M" ] || { echo "no manifest at $M"; exit 1; }

if command -v rc-update >/dev/null 2>&1; then
    for s in pipewire-pulse wireplumber pipewire; do
        rc-service "$s" stop >/dev/null 2>&1 || true
        rc-update del "$s" default >/dev/null 2>&1 || true
    done
fi

while IFS= read -r f; do
    case "$f" in
        /usr/local/libexec/hdx-pw-run|/etc/init.d/*|/etc/service/*|/etc/dinit.d/*|/etc/alsa/conf.d/*pipewire*.conf) rm -f "$f" ;;
    esac
done < "$M"
# runit service directories we created (only if empty after removing run)
for s in pipewire wireplumber pipewire-pulse; do rmdir "/etc/service/$s" 2>/dev/null || true; done

rmdir /etc/alsa/conf.d /etc/alsa 2>/dev/null || true

rm -f "$M"
true
