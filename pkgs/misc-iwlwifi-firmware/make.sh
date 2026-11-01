SRC="${HDX_SRC:-/hdxp/src/misc-iwlwifi-firmware-src}"
TAG=20261019
FW=iwlwifi-QuZ-a0-hr-b0-77.ucode
if [ ! -d "$SRC/.git" ]; then
    git clone --depth 1 --branch "$TAG" --filter=blob:none --sparse \
        https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git "$SRC"
fi
cd "$SRC"
# just this one file (and the license): newer tags keep it in intel/iwlwifi/, older ones at the top level
git sparse-checkout set --no-cone "/$FW" "/intel/iwlwifi/$FW" /LICENCE.iwlwifi_firmware
if [ -s "intel/iwlwifi/$FW" ]; then
    FILE="intel/iwlwifi/$FW"
elif [ -s "$FW" ]; then
    FILE="$FW"
else
    echo "$FW is missing or empty in the linux-firmware $TAG checkout" >&2
    exit 1
fi
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU mkdir -p /lib/firmware
$SU cp -f "$FILE" "/lib/firmware/$FW"
if [ -f LICENCE.iwlwifi_firmware ]; then
    $SU cp -f LICENCE.iwlwifi_firmware /lib/firmware/
fi
