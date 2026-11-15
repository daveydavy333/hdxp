if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU rm -f /usr/local/bin/pkexec /usr/local/bin/pkcheck /usr/local/bin/pkaction /usr/local/bin/pkttyagent
$SU rm -rf /usr/local/lib/polkit-1 /usr/local/include/polkit-1 /usr/local/share/polkit-1
$SU rm -f /usr/local/lib/libpolkit-gobject-1.so* /usr/local/lib/libpolkit-agent-1.so* \
          /usr/local/lib/pkgconfig/polkit-gobject-1.pc /usr/local/lib/pkgconfig/polkit-agent-1.pc \
          /usr/local/share/dbus-1/system-services/org.freedesktop.PolicyKit1.service \
          /usr/local/share/dbus-1/system.d/org.freedesktop.PolicyKit1.conf \
          /usr/local/share/gettext/its/polkit.its /usr/local/share/gettext/its/polkit.loc
# /etc/polkit-1 (your rules) and the polkitd user are left alone on purpose
