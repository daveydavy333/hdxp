# removes exactly what make.sh installed, using the manifest it saved
[ -n "$HDX_PKG" ] || { echo "HDX_PKG is empty, refusing to continue"; exit 1; }
M="/usr/local/share/hdxp-manifests/$HDX_PKG.txt"
[ -f "$M" ] || { echo "no manifest at $M"; exit 1; }
while IFS= read -r f; do
    case "$f" in
        /usr/local/*|/etc/*|/usr/share/*)
            if [ -f "$f" ] || [ -L "$f" ]; then
                rm -f "$f"
                d=$(dirname "$f")
                # only tidy deeper directories (share/doc/x, etc/xdg/x), never bin, lib or share themselves
                if [ "$(printf '%s' "$d" | tr -cd / | wc -c)" -ge 5 ]; then rmdir "$d" 2>/dev/null || true; fi
            fi
            ;;
    esac
done < "$M"
rm -f "$M"
if [ -f /etc/shells ]; then sed -i '\|^/usr/local/bin/oksh$|d' /etc/shells; fi
true
