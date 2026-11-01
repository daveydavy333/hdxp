# removes what sys-runit installed apart from the /usr/local/bin tools (hdx removes those)
rm -f /sbin/runit /sbin/runit-init
rm -rf /etc/runit
rm -f /etc/service/net /etc/service/getty-tty1
rm -f /usr/local/sbin/poweroff /usr/local/sbin/reboot /usr/local/sbin/halt
echo "note: make sure no limine entry still boots with init=/sbin/runit-init"
