SRC="${HDX_SRC:-/hdxp/src/util-swaylock-src}"
PKG="${HDX_PKG:-util-swaylock}"
VER=1.8.6
SHA256=904376fd012bfff888d042606539c677d90e11f8beeeccc50a9fe387fc41a686
TARBALL="swaylock-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/swaywm/swaylock/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "swaylock-$VER" ] || tar xf "$TARBALL"
cd "swaylock-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
rm -rf build
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release -Dpam=disabled -Dgdk-pixbuf=enabled -Dman-pages=enabled -Dzsh-completions=false -Dbash-completions=false -Dfish-completions=false
meson compile -C build
$SU /usr/local/bin/meson install -C build --no-rebuild
# the install log is what uninstall.sh removes, so nothing is guessed on removal
$SU install -Dm644 build/meson-logs/install-log.txt "/usr/local/share/hdxp-manifests/$PKG.txt"
# without PAM swaylock checks the password against /etc/shadow, which only root can read: it has to be setuid root
$SU chown root:root /usr/local/bin/swaylock
$SU chmod u+s /usr/local/bin/swaylock
echo "util-swaylock: installed setuid root (no PAM). your user needs a password set (passwd), otherwise you cannot unlock"
echo "util-swaylock: test it first with a second tty or ssh open, so you can pkill swaylock if something is wrong"
sync
