SRC="${HDX_SRC:-/hdxp/src/base-situation-src}"
[ -d "$SRC/.git" ] || git clone https://codeberg.org/derivelinux/situation "$SRC"
# pinned to the commit tested in the first hdxi boot
git -C "$SRC" checkout -q ec064d44f0d819f8523633851abc9b547bff6eb1
cd "$SRC"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU sh ./install.sh
# install.sh makes absolute //bin/... links; initramfs checks need relative ones
$SU ln -sf ../bin/situation /sbin/init
$SU ln -sf situation /bin/init
