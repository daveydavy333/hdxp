set -e
SRC="${HDX_SRC:-/hdxp/src/devel-gdk-pixbuf-src}"
VER=2.42.12
SHA256=b9505b3445b9a7e48ced34760c3bcb73e966df3ac94c95a148cb669ab748e3c7
TARBALL="gdk-pixbuf-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://download.gnome.org/sources/gdk-pixbuf/${VER%.*}/$TARBALL"
if [ "$SHA256" = FILL_ME ]; then
  sha256sum "$TARBALL"
  echo "pin the SHA256 above in make.sh, then run it again" >&2
  exit 1
fi
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "gdk-pixbuf-$VER" ] || tar -xf "$TARBALL"
cd "gdk-pixbuf-$VER"

# Switch off what we don't need, whether the option is a boolean or a
# feature in this version, and skip options that don't exist in it.
off() {
  b=$(awk -v n="option('$1'" 'index($0,n){f=1} /option\(/ && !index($0,n){f=0} f' meson_options.txt)
  [ -n "$b" ] || return 0
  if printf '%s\n' "$b" | grep -q "'feature'"; then echo "-D$1=disabled"; else echo "-D$1=false"; fi
}
OPTS="$(off tiff) $(off introspection) $(off gir) $(off man) $(off docs) $(off gtk_doc) \
$(off installed_tests) $(off tests) $(off gio_sniffing) $(off thumbnailer)"
echo "gdk-pixbuf extra options: $OPTS"

rm -rf build
# png + jpeg are built into the library, so there are no loader modules
# and no loaders.cache to keep in sync.
meson setup build --prefix=/usr/local --libdir=lib --buildtype=release --wrap-mode=nofallback \
  -Dbuiltin_loaders=png,jpeg $OPTS
meson compile -C build
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU /usr/local/bin/meson install -C build --no-rebuild
