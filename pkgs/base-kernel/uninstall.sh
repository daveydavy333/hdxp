# runs as root from the port folder, after you confirm.
# removes the kernel this port installed. the version comes from make.sh,
# so the two files can never disagree.
VER=$(sed -n 's/^VER=//p' ./make.sh)
case "$VER" in
    ''|*/*) echo "cannot read a sane VER from make.sh"; exit 1 ;;
esac
if [ "$(uname -r)" = "$VER" ]; then
    echo "note: $VER is the kernel you are running right now"
fi
# /boot/vmlinuz is a copy of the newest kernel; only remove it if it is this one
if [ -f /boot/vmlinuz ] && cmp -s /boot/vmlinuz "/boot/vmlinuz-$VER"; then
    rm -f /boot/vmlinuz
fi
rm -f "/boot/vmlinuz-$VER" "/boot/config-$VER" "/boot/System.map-$VER"
rm -rf "/lib/modules/$VER"
