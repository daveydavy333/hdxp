if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU rm -f /usr/local/bin/iwctl /usr/local/bin/iwmon /usr/local/libexec/iwd /usr/local/share/dbus-1/system.d/iwd-dbus.conf
$SU rm -f /etc/dinit.d/iwd
$SU rm -rf /etc/service/iwd
# /var/lib/iwd (saved networks) is left alone on purpose
