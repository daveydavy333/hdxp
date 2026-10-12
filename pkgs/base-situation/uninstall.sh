# runs as root from the port folder, after you confirm.
# hdx removes the binaries itself (situation, sctl, init, poweroff, reboot, halt).
# this removes the rest of what install.sh put down.
rm -f /lib/situation.sh
rm -f /etc/rc.d/boot/00-firmware.sh /etc/rc.d/boot/10-audio-perms.sh
# only remove /sbin/init if it is the link this port made
if [ "$(readlink /sbin/init)" = ../bin/situation ]; then
    rm -f /sbin/init
fi
# /etc/rc.d, /etc/sv and any scripts of your own are left alone
