if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU rm -f /usr/local/bin/dbus-cleanup-sockets /usr/local/bin/dbus-daemon /usr/local/bin/dbus-launch /usr/local/bin/dbus-monitor \
          /usr/local/bin/dbus-run-session /usr/local/bin/dbus-send /usr/local/bin/dbus-test-tool \
          /usr/local/bin/dbus-update-activation-environment /usr/local/bin/dbus-uuidgen
$SU rm -rf /usr/local/lib/dbus-1.0 /usr/local/lib/cmake/DBus1 /usr/local/include/dbus-1.0 /usr/local/libexec/dbus-daemon-launch-helper
$SU rm -f /usr/local/lib/libdbus-1.so* /usr/local/lib/pkgconfig/dbus-1.pc
$SU rm -f /usr/local/share/dbus-1/session.conf /usr/local/share/dbus-1/system.conf
$SU rm -rf /usr/local/share/xml/dbus-1
$SU rm -f /etc/rc.d/boot/12-dbus.sh /etc/dinit.d/dbus
$SU rm -rf /etc/service/dbus
# /etc/dbus-1, /etc/machine-id, /usr/local/share/dbus-1/{system-services,system.d} (polkit's files) and the messagebus user stay
