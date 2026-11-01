SRC="${HDX_SRC:-/hdxp/src/base-bootscripts-src}"
# the boot scripts every init runs from /etc/rc.d/boot (situation and runit both do).
# they are written from this file, so there are no other files to lose.
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
mkdir -p "$SRC"
cd "$SRC"

cat > 00-firmware.sh <<'EOF_FW'
#!/bin/sh
# 00-firmware.sh - Load common firmware, early

load() {
	mod="$1"
	grep -q "^$mod " /proc/modules 2>/dev/null && return
	modprobe "$mod" 2>/dev/null || :
}

# Intel GPU
load i915
# Intel Wi-Fi stack
load iwlwifi
load iwlmvm
# AMD GPU
load amdgpu
# Realtek Wi-Fi
load rtw88_core
load rtw88_pci
load rtw88_8822ce
load rtw88_8821ce
# Broadcom Wi-Fi
load brcmfmac
# Bluetooth USB
load btusb
# Generic USB audio
load snd_usb_audio
EOF_FW

cat > 04-fsck.sh <<'EOF_FSCK'
#!/bin/sh
# 04-fsck.sh - check vfat filesystems from /etc/fstab before they get mounted.
# fat has no journal, so an unclean shutdown can leave the esp dirty.
# (the root filesystem is ext4, which replays its journal when it mounts.)
# wrapped in a function so it is safe whether situation runs or sources it.

hdx_fsck() {
    local fstab="${FSTAB:-/etc/fstab}" dev mnt type rest rc
    command -v fsck.vfat >/dev/null 2>&1 || return 0
    [ -r "$fstab" ] || return 0
    while read -r dev mnt type rest; do
        case "$dev" in ''|'#'*) continue ;; esac
        [ "$type" = vfat ] || continue
        case "$dev" in
            LABEL=*|UUID=*|PARTUUID=*) dev=$(findfs "$dev" 2>/dev/null) || continue ;;
        esac
        [ -e "$dev" ] || continue
        # never check a mounted filesystem
        mountpoint -q "$mnt" 2>/dev/null && continue
        echo "fsck: checking $dev ($mnt)"
        fsck.vfat -a "$dev" </dev/null
        rc=$?
        [ "$rc" -le 1 ] || echo "fsck: $dev exited with status $rc"
    done < "$fstab"
    return 0
}
hdx_fsck
EOF_FSCK

cat > 05-mount.sh <<'EOF_MOUNT'
#!/bin/sh
# 05-mount.sh - mount filesystems listed in /etc/fstab (situation does not)
[ -s /etc/fstab ] && mount -a 2>/dev/null
:
EOF_MOUNT

cat > 10-audio-perms.sh <<'EOF_AUDIO'
#!/bin/sh
grp=audio
for d in /dev/audio* /dev/snd/*; do
	[ -e "$d" ] || continue
	chgrp "$grp" "$d" 2>/dev/null
	chmod 660 "$d" 2>/dev/null
done
EOF_AUDIO

$SU mkdir -p /etc/rc.d/boot
for f in 00-firmware.sh 04-fsck.sh 05-mount.sh 10-audio-perms.sh; do
    [ -s "$f" ] || { echo "$f came out empty"; exit 1; }
    sh -n "$f" || { echo "$f has a syntax error"; exit 1; }
    $SU install -m 755 "$f" "/etc/rc.d/boot/$f"
done
sync
