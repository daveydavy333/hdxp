#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-misc-gomono-nerd-fonts}"
SRC="${HDX_SRC:-/hdxp/src/misc-gomono-nerd-fonts-src}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
mkdir -p "$SRC"
cd "$SRC"

VER=v3.5.1
F="Go-Mono-$VER.tar.xz"
SHA=d993c556cf0e7c4b2455628063a5adb441b3517a297783185c262d77900d70dd
[ -f "$F" ] || curl -fL -o "$F" "https://github.com/ryanoasis/nerd-fonts/releases/download/$VER/Go-Mono.tar.xz"
echo "$SHA  $F" | sha256sum -c - >/dev/null || { echo "misc-gomono-nerd-fonts: checksum mismatch" >&2; rm -f "$F"; exit 1; }
rm -rf gomono && mkdir gomono
tar xf "$F" -C gomono

D=/usr/local/share/fonts/gomono
$SU mkdir -p "$D"
for f in GoMonoNerdFont-Regular GoMonoNerdFont-Bold GoMonoNerdFont-Italic GoMonoNerdFont-BoldItalic; do
    $SU install -m644 "gomono/$f.ttf" "$D/"
done
# hack (and anything else written for Arch) looks here: keep a symlink as a fallback
$SU mkdir -p /usr/share/fonts/TTF
$SU ln -sf "$D/GoMonoNerdFont-Regular.ttf" /usr/share/fonts/TTF/GoMonoNerdFont-Regular.ttf
if command -v fc-cache >/dev/null 2>&1; then $SU fc-cache -f "$D" || true; fi
sync
