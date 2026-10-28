#!/bin/sh
DEST="${DESTDIR:-}"
LIST="$DEST/usr/share/hdxi/firefox-created.txt"
[ -f "$LIST" ] || { echo "no firefox file list at $LIST" >&2; exit 1; }
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
sort -r "$LIST" | while IFS= read -r p; do
  $SU rm -f "$DEST/$p"
done
# remove directories left empty
sort -r "$LIST" | while IFS= read -r p; do
  $SU rmdir -p "$DEST/$(dirname "$p")" 2>/dev/null
done
$SU rm -f "$DEST/usr/local/bin/firefox" "$LIST"
exit 0
