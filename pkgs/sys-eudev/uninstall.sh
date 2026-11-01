# removes what sys-eudev installed apart from udevadm (hdx removes that one)
pkill udevd 2>/dev/null || true
rm -f /etc/rc.d/boot/03-udev.sh /usr/local/sbin/udevd
rm -rf /usr/local/lib/udev /etc/udev
rm -f /usr/local/lib/libudev.* /usr/local/lib/pkgconfig/libudev.pc /usr/local/include/libudev.h
echo "note: libudev is gone. reinstall it with: hdx i -f devel-libudev-zero"
