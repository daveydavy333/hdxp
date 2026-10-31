VER=12.4.1
SHA=aa43fd0124096014c5849d63249765ab396d57b2e192ce7da9c8999da0f282e9
TAR="limine-$VER.tar.xz"
SRC="${HDX_SRC:-/hdxp/src/base-limine-src}"

mountpoint -q /boot || { echo "mount your EFI System Partition at /boot first"; exit 1; }

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fLO "https://github.com/limine-bootloader/limine/releases/download/v$VER/$TAR"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "limine-$VER" ] || tar -xf "$TAR"
cd "limine-$VER"

CC_FOR_TARGET=gcc LD_FOR_TARGET=ld OBJCOPY_FOR_TARGET=objcopy OBJDUMP_FOR_TARGET=objdump READELF_FOR_TARGET=readelf ./configure --prefix=/usr --enable-uefi-x86-64
make -j"$(nproc)"

if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install

EFI=/usr/share/limine/BOOTX64.EFI
[ -f "$EFI" ] || { echo "expected $EFI, found:"; ls /usr/share/limine; exit 1; }
$SU mkdir -p /boot/EFI/BOOT
$SU cp "$EFI" /boot/EFI/BOOT/BOOTX64.EFI
