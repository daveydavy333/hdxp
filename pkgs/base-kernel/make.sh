[ -n "$HDX_BOOT_ANYWHERE" ] || mountpoint -q /boot || { echo "mount your ESP at /boot first (or set HDX_BOOT_ANYWHERE=1)"; exit 1; }
VER=6.18.55
SHA=f410638061a165c12f42ab871d2f3fcd525515359b5faeee80969cff84524df9
TAR="linux-$VER.tar.xz"
SRC="${HDX_SRC:-/hdxp/src/base-kernel-src}"

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fLO "https://cdn.kernel.org/pub/linux/kernel/v6.x/$TAR"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "linux-$VER" ] || tar -xf "$TAR"
cd "linux-$VER"

make defconfig kvm_guest.config
for o in EXT4_FS VIRTIO_BLK VIRTIO_PCI VIRTIO_NET DEVTMPFS UEVENT_HELPER; do
    scripts/config --enable "$o"
done
scripts/config --disable DEBUG_INFO_BTF
scripts/config --enable FB --enable DRM_FBDEV_EMULATION --enable FRAMEBUFFER_CONSOLE --enable FRAMEBUFFER_CONSOLE_DETECT_PRIMARY --enable SYSFB_SIMPLEFB --enable DRM_SIMPLEDRM
scripts/config --enable MMC --enable MMC_BLOCK --enable MMC_SDHCI --enable MMC_SDHCI_PCI --enable BLK_DEV_SD --enable SATA_AHCI --enable USB_XHCI_HCD --enable USB_XHCI_PCI --enable USB_EHCI_HCD --enable USB_EHCI_PCI --enable USB_STORAGE --enable USB_HID --enable HID_GENERIC --enable KEYBOARD_ATKBD
scripts/config --enable PCI --enable WIRELESS --enable CFG80211 --enable MAC80211 --enable RFKILL --enable WLAN --enable WLAN_VENDOR_ATH --enable ATH10K --enable ATH10K_PCI --enable FW_LOADER
# the wifi firmware is built into the kernel (no initramfs to load it from), so it has to be installed first
ATH_FW=ath10k/QCA9377/hw1.0
if [ -f "/lib/firmware/$ATH_FW/firmware-6.bin" ]; then
    scripts/config --set-str EXTRA_FIRMWARE "$ATH_FW/firmware-6.bin $ATH_FW/board-2.bin $ATH_FW/board.bin"
    scripts/config --set-str EXTRA_FIRMWARE_DIR /lib/firmware
else
    echo "note: no ath10k firmware in /lib/firmware, building without it (hdx i misc-ath10k-firmware first for wifi)"
fi
scripts/config --set-str UEVENT_HELPER_PATH ""
make olddefconfig

make -j"$(nproc)"

if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU mkdir -p /boot
$SU cp arch/x86/boot/bzImage "/boot/vmlinuz-$VER"
$SU cp arch/x86/boot/bzImage /boot/vmlinuz
$SU cp .config "/boot/config-$VER"
$SU cp System.map "/boot/System.map-$VER"
$SU make modules_install
