if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU rm -f /usr/local/bin/9
$SU rm -rf /usr/local/plan9
