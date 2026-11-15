if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU rm -f /etc/rc.d/boot/11-alsa.sh
# /var/lib/alsa/asound.state is left alone on purpose
