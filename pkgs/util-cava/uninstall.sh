rm -f /usr/local/share/cava/config.example /usr/local/share/cava/asound.conf.example
if grep -q snd-aloop /etc/rc.d/boot/13-aloop.sh 2>/dev/null; then
    rm -f /etc/rc.d/boot/13-aloop.sh
fi
rm -f /usr/local/share/cava/themes/solarized_dark /usr/local/share/cava/themes/tricolor
rmdir /usr/local/share/cava/themes /usr/local/share/cava 2>/dev/null || true
