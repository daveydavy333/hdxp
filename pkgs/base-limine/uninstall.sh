# runs as root from the port folder, after you confirm.
# hdx removes /usr/bin/limine itself. this removes the rest.
# only remove the efi loader if it is the one this port installed
if [ -f /boot/EFI/BOOT/BOOTX64.EFI ] && [ -f /usr/share/limine/BOOTX64.EFI ] \
   && cmp -s /boot/EFI/BOOT/BOOTX64.EFI /usr/share/limine/BOOTX64.EFI; then
    rm -f /boot/EFI/BOOT/BOOTX64.EFI
fi
rm -rf /usr/share/limine
# /boot/limine.conf is yours and is left alone
