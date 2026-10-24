SRC="${HDX_SRC:-/hdxp/src/misc-ath10k-firmware-src}"
TAG=REPLACE_ME
if [ "$TAG" = REPLACE_ME ]; then
    echo "misc-ath10k-firmware: pin TAG (a linux-firmware release tag) in make.sh first" >&2
    exit 1
fi
if [ ! -d "$SRC/.git" ]; then
    git clone --depth 1 --branch "$TAG" --filter=blob:none --sparse \
        https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git "$SRC"
fi
cd "$SRC"
git sparse-checkout set ath10k/QCA9377
[ -d ath10k/QCA9377 ] || { echo "ath10k/QCA9377 missing from checkout" >&2; exit 1; }
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU mkdir -p /lib/firmware/ath10k
$SU cp -a ath10k/QCA9377 /lib/firmware/ath10k/
if [ -f LICENSE.QualcommAtheros_ath10k ]; then
    $SU cp -f LICENSE.QualcommAtheros_ath10k /lib/firmware/ath10k/QCA9377/
fi
