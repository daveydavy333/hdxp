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
scripts/config --enable MMC --enable MMC_BLOCK --enable MMC_SDHCI --enable MMC_SDHCI_PCI --enable BLK_DEV_SD --enable SATA_AHCI --enable BLK_DEV_NVME --enable USB_XHCI_HCD --enable USB_XHCI_PCI --enable USB_EHCI_HCD --enable USB_EHCI_PCI --enable USB_STORAGE --enable USB_HID --enable HID_GENERIC --enable KEYBOARD_ATKBD
scripts/config --enable PCI --enable WIRELESS --enable CFG80211 --enable MAC80211 --enable RFKILL --enable WLAN --enable WLAN_VENDOR_ATH --enable ATH10K --enable ATH10K_PCI --enable WLAN_VENDOR_INTEL --enable IWLWIFI --enable IWLMVM --enable FW_LOADER
# wifi firmware is built into the kernel (no initramfs to load it from), so it has to be installed first
FW=""
ATH_FW=ath10k/QCA9377/hw1.0
if [ -f "/lib/firmware/$ATH_FW/firmware-6.bin" ]; then
    FW="$ATH_FW/firmware-6.bin $ATH_FW/board-2.bin $ATH_FW/board.bin"
else
    echo "note: no ath10k firmware in /lib/firmware, building without it (hdx i misc-ath10k-firmware first for wifi)"
fi
IWL_FW=iwlwifi-QuZ-a0-hr-b0-77.ucode
if [ -s "/lib/firmware/$IWL_FW" ]; then
    FW="$FW $IWL_FW"
elif [ -e "/lib/firmware/$IWL_FW" ]; then
    echo "error: /lib/firmware/$IWL_FW is empty, reinstall it (hdx i -f misc-iwlwifi-firmware)"
    exit 1
else
    echo "note: no iwlwifi firmware in /lib/firmware, building without it (hdx i misc-iwlwifi-firmware first for intel wifi)"
fi
# amd graphics (stoney: the a6-9220e and friends). amdgpu is built in, like the wifi drivers, so its firmware
# has to be built in too. it is only enabled when all of it is installed: an amdgpu without its firmware takes
# the screen over from simpledrm and then fails, which leaves no display at all.
# (hdx i misc-amdgpu-firmware first)
AMD_FW=""
AMD_OK=1
for f in ce pfp me mec rlc sdma uvd vce; do
    if [ -s "/lib/firmware/amdgpu/stoney_$f.bin" ]; then
        AMD_FW="$AMD_FW amdgpu/stoney_$f.bin"
    else
        AMD_OK=0
    fi
done
if [ "$AMD_OK" -eq 1 ]; then
    scripts/config --enable DRM_AMDGPU --enable DRM_AMD_DC
    FW="$FW$AMD_FW"
else
    echo "note: no (or incomplete) amdgpu firmware in /lib/firmware, building without amdgpu (hdx i misc-amdgpu-firmware first for amd graphics)"
fi
# intel graphics (tiger lake and friends). i915 comes from the defconfig and drives the screen without any
# firmware, but without the DMC firmware runtime power management is disabled, so this one is optional
# (hdx i misc-i915-firmware first for intel graphics power management).
scripts/config --enable DRM_I915
I915_FW=i915/tgl_dmc_ver2_12.bin
if [ -s "/lib/firmware/$I915_FW" ]; then
    FW="$FW $I915_FW"
else
    echo "note: no i915 DMC firmware in /lib/firmware, building without it (hdx i misc-i915-firmware first for intel graphics power management)"
fi
# i2c-hid touchpads behind the intel LPSS controller (laptops like the hp elitebook). built in, no initramfs.
TP_OPTS="I2C I2C_HID_ACPI I2C_DESIGNWARE_PLATFORM MFD_INTEL_LPSS_PCI MFD_INTEL_LPSS_ACPI PINCTRL_TIGERLAKE HID_MULTITOUCH INPUT_MOUSE"
for o in $TP_OPTS; do
    scripts/config --enable "$o"
done
if [ -n "$FW" ]; then
    scripts/config --set-str EXTRA_FIRMWARE "${FW# }"
    scripts/config --set-str EXTRA_FIRMWARE_DIR /lib/firmware
fi
scripts/config --set-str UEVENT_HELPER_PATH ""
make olddefconfig
for o in $TP_OPTS; do
    grep -q "^CONFIG_$o=y" .config || echo "note: CONFIG_$o did not stay enabled (touchpad support may be incomplete)"
done
if [ "$AMD_OK" -eq 1 ] && ! grep -q '^CONFIG_DRM_AMDGPU=y' .config; then
    echo "error: DRM_AMDGPU did not stay enabled in the config (a dependency is missing)"
    exit 1
fi

make -j"$(nproc)"

if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU mkdir -p /boot
$SU cp arch/x86/boot/bzImage "/boot/vmlinuz-$VER"
$SU cp arch/x86/boot/bzImage /boot/vmlinuz
$SU cp .config "/boot/config-$VER"
$SU cp System.map "/boot/System.map-$VER"
$SU make modules_install
