SRC="${HDX_SRC:-/hdxp/src/misc-i915-firmware-src}"
TAG=20260622
BASE="https://gitlab.com/kernel-firmware/linux-firmware/-/raw/$TAG/i915"
# the firmware the i915 driver asks for on Intel Tiger Lake graphics (11th gen core)
SUMS="3c013ef0ad96ba73aee8e5bd04a8e27cc9b1c6e9183b1a83ce124485f325afca  tgl_dmc_ver2_12.bin"
mkdir -p "$SRC"
cd "$SRC"
FILES="$(printf '%s\n' "$SUMS" | awk '{print $2}')"
for f in $FILES; do
  [ -s "$f" ] || curl -fL -o "$f" "$BASE/$f"
done
printf '%s\n' "$SUMS" | sha256sum -c -
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU mkdir -p /lib/firmware/i915
for f in $FILES; do
  $SU install -m 644 "$f" "/lib/firmware/i915/$f"
done
