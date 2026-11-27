# removes exactly what make.sh installed, using the install manifest it saved
[ -n "$HDX_PKG" ] || { echo "HDX_PKG is empty, refusing to continue"; exit 1; }
M="/usr/local/share/hdxp-manifests/$HDX_PKG.txt"
[ -f "$M" ] || { echo "no manifest at $M"; exit 1; }

while IFS= read -r f; do
    case "$f" in
        /usr/local/?*|/etc/*) rm -f "$f" ;;
    esac
done < "$M"

# empty directories left behind, deepest first; /usr/local/<x> itself is never touched
awk '/^\/usr\/local\// { n = split($0, p, "/"); d = ""; for (i = 2; i < n; i++) { d = d "/" p[i]; if (i >= 5) print d } }' "$M" \
    | sort -u | awk '{ print length($0), $0 }' | sort -rn | cut -d' ' -f2- \
    | while IFS= read -r d; do rmdir "$d" 2>/dev/null || true; done

rm -f "$M"
true
