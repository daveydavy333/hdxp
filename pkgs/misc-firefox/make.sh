SRC="${HDX_SRC:-/hdxp/src/misc-firefox-src}"
VER=151.0.3-r0-alpine3.24
BUNDLE="firefox-bundle-$VER.tar.xz"
URL="${HDX_URL:-https://github.com/daveydavy333/HDXI/releases/download/firefox-151.0.3/$BUNDLE}"
SHA256=5f0b7bd02e712b5635ce53129d24eef6379d4ba028cd0553753b4a16a26fcbb0
DEST="${DESTDIR:-}"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$BUNDLE" ] || curl -fL -o "$BUNDLE" "$URL"
echo "$SHA256  $BUNDLE" | sha256sum -c -
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

# note which files this port creates, so removing it never deletes files the system already had
MANIFEST=usr/share/hdxi/firefox-manifest.txt
rm -f "$MANIFEST"
tar xJf "$BUNDLE" "$MANIFEST"
: > created.txt
while IFS= read -r p; do
  [ -e "$DEST/$p" ] || [ -L "$DEST/$p" ] || echo "$p" >> created.txt
done < "$MANIFEST"

$SU mkdir -p "$DEST/usr/share/hdxi" "$DEST/usr/local/bin"
$SU tar xJf "$BUNDLE" -C "${DEST:-/}"
$SU cp created.txt "$DEST/usr/share/hdxi/firefox-created.txt"

printf '#!/bin/sh\nexport MOZ_ENABLE_WAYLAND=1\nexec /usr/lib/firefox/firefox "$@"\n' > firefox-wrapper
$SU install -m 755 firefox-wrapper "$DEST/usr/local/bin/firefox"
