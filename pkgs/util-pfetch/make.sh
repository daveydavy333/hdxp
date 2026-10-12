SRC="${HDX_SRC:-/hdxp/src/util-pfetch-src}"
[ -d "$SRC/.git" ] || git clone https://github.com/Un1q32/pfetch "$SRC"
cd "$SRC"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU install -Dm755 pfetch /usr/local/bin/pfetch
