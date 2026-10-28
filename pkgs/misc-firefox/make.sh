SRC="${HDX_SRC:-/hdxp/src/misc-firefox-src}"
VER=151.0.3-r0-alpine3.24
BUNDLE="firefox-bundle-$VER.tar.xz"
TAG=firefox-151.0.3
URL="${HDX_URL:-https://github.com/daveydavy333/hdxp/releases/download/$TAG/$BUNDLE}"
SHA256=6e329930a11eb0619baffaee6de5fd5c4933d6b37290fbefe4e3e778ce730c53
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

# put the system library directories ahead of /usr/local/lib: Firefox needs its own patched libpng (APNG) and
# other library versions that differ from the ones built into /usr/local
printf '#!/bin/sh\nexport MOZ_ENABLE_WAYLAND=1\nexport LD_LIBRARY_PATH=/usr/lib:/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\nexec /usr/lib/firefox/firefox "$@"\n' > firefox-wrapper
$SU install -m 755 firefox-wrapper "$DEST/usr/local/bin/firefox"
