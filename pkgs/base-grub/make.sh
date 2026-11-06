VER=2.14
SHA=bc8d3c73535b8838d8c8e2654d73edc4e6ae8c8acdb45d5df5dc9a1547446d43
TAR="grub-$VER.tar.xz"
SRC="${HDX_SRC:-/hdxp/src/base-grub-src}"

mountpoint -q /boot || { echo "mount your EFI System Partition at /boot first"; exit 1; }

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fLO "https://ftp.gnu.org/gnu/grub/$TAR"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "grub-$VER" ] || tar -xf "$TAR"
cd "grub-$VER"

# musl has no sys/cdefs.h, and grub's committed gnulib headers include it unconditionally;
# an empty one is enough, the headers define the macros they need themselves
mkdir -p "$SRC/shim/sys"
: > "$SRC/shim/sys/cdefs.h"

# gcc 15 defaults to C23, which breaks old gnulib code and grub's own headers
export CFLAGS="-O2 -std=gnu17 -I$SRC/shim"
export CPPFLAGS="-I$SRC/shim"
export TARGET_CFLAGS="-Os -std=gnu17"

./configure --prefix=/usr --sysconfdir=/etc \
    --with-platform=efi --target=x86_64 \
    --disable-werror --disable-nls \
    --disable-grub-mkfont --disable-grub-mount \
    --disable-device-mapper --disable-libzfs --disable-liblzma
make -j"$(nproc)"

if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install

MODDIR=/usr/lib/grub/x86_64-efi
[ -d "$MODDIR" ] || { echo "expected $MODDIR, found:"; ls /usr/lib/grub; exit 1; }

# one standalone EFI image with everything needed to read the ESP and boot a kernel;
# the prefix has no device, so grub looks for /grub/grub.cfg on the partition it booted from
MODS="part_gpt part_msdos fat ext2 normal linux boot configfile echo ls cat test search search_fs_uuid search_label all_video gzio"
IMG="$SRC/BOOTX64.EFI"
grub-mkimage -O x86_64-efi -d "$MODDIR" -p /grub -o "$IMG" $MODS

DEST=/boot/EFI/BOOT/BOOTX64.EFI
$SU mkdir -p /boot/EFI/BOOT /boot/grub/x86_64-efi
# base-limine uses the same path: keep whatever was there
[ -f "$DEST" ] && $SU cp "$DEST" "$DEST.old"
$SU cp "$IMG" "$DEST"
$SU cp "$MODDIR"/*.mod "$MODDIR"/*.lst /boot/grub/x86_64-efi/

echo "grub installed. now write /boot/grub/grub.cfg (see installation.md step 6)"
