set -e
SRC="${HDX_SRC:-/hdxp/src/util-yambar-src}"
VER=1.11.0
SHA256=f3a1f66f05852c6443f46dbdae58eb9a7cbf1a15b32b11ba90c2c7e907fbaf5f
TARBALL="yambar-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/universe/y/yambar/yambar_$VER.orig.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "yambar-$VER" ] || tar -xf "$TARBALL"
cd "yambar-$VER"

# yambar 1.11 requires fcft 3.x (>=3.0.0, <4.0.0)
PKGCONF=$(command -v pkgconf || command -v pkg-config)
FCFT=$("$PKGCONF" --modversion fcft 2>/dev/null || true)
case "$FCFT" in
  3.*) echo "yambar will build against fcft $FCFT" ;;
  *) echo "yambar $VER needs fcft 3.x, found: ${FCFT:-none}" >&2; exit 1 ;;
esac

rm -rf build
# Wayland only (no X11). Core modules are built into the binary.
# Disabled: alsa, mpd, pipewire, pulse, removables (libraries not in the tree).
# battery and backlight need libudev (pkg-config name: libudev).
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release --wrap-mode=nofallback \
  -Dwerror=false -Dbackend-x11=disabled -Dbackend-wayland=enabled \
  -Dplugin-clock=enabled -Dplugin-label=enabled -Dplugin-cpu=enabled -Dplugin-mem=enabled \
  -Dplugin-disk-io=enabled -Dplugin-network=enabled -Dplugin-script=enabled \
  -Dplugin-battery=enabled -Dplugin-backlight=enabled \
  -Dplugin-i3=enabled -Dplugin-sway-xkb=enabled -Dplugin-dwl=enabled \
  -Dplugin-river=enabled -Dplugin-foreign-toplevel=enabled \
  -Dplugin-alsa=disabled -Dplugin-mpd=disabled -Dplugin-pipewire=disabled \
  -Dplugin-pulse=disabled -Dplugin-removables=disabled \
  -Dplugin-xkb=disabled -Dplugin-xwindow=disabled
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild

# Starter config for sway (validated with: yambar --validate -c config.example.yml).
# Copy it to ~/.config/yambar/config.yml.
$SU mkdir -p /usr/local/share/yambar
$SU tee /usr/local/share/yambar/config.example.yml >/dev/null <<'YAMBAR_CFG_EOF'
# Starter yambar config for sway (copy to ~/.config/yambar/config.yml).
# Check any edit with: yambar --validate -c ~/.config/yambar/config.yml
# Module and tag docs: man yambar-modules, man yambar-tags
bar:
  height: 26
  location: top
  font: DejaVu Sans Mono:pixelsize=13
  foreground: e6e6e6ff
  background: 1a1a1aff
  spacing: 10
  margin: 8

  left:
    - i3:
        content:
          "":
            map:
              default:
                string: {text: "{name}", margin: 6}
              conditions:
                state == focused:
                  string:
                    text: "{name}"
                    margin: 6
                    deco: {underline: {size: 2, color: 5fafffff}}
                state == urgent:
                  string: {text: "{name}", margin: 6, foreground: ff5f5fff}

  center:
    - clock:
        content:
          - string: {text: "{date}"}
          - string: {text: "{time}"}

  right:
    - cpu:
        poll-interval: 2000
        content:
          map:
            conditions:
              id < 0:
                string: {text: "cpu {cpu}%"}
    - mem:
        poll-interval: 5000
        content:
          string: {text: "mem {percent_used}%"}
    - battery:
        name: BAT0
        poll-interval: 30000
        content:
          string: {text: "bat {capacity}% {state}"}
YAMBAR_CFG_EOF
