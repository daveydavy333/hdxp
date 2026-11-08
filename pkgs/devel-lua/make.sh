SRC="${HDX_SRC:-/hdxp/src/devel-lua-src}"
VER=5.5.1
# fill in: sha256sum lua-5.5.1.tar.gz (from https://www.lua.org/ftp/lua-5.5.1.tar.gz)
SHA256=1c4b4068d67061f2a2231ad2b5422e77acea1487ea9890f6320af614f4373dce
TARBALL="lua-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://www.lua.org/ftp/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "lua-$VER" ] || tar -xf "$TARBALL"
cd "lua-$VER"
make clean
make -j"$(nproc)" posix MYCFLAGS=-fPIC
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install INSTALL_TOP=/usr/local
# lua's own install has no pkg-config file, hyprland finds lua through pkg-config
cat > lua5.5.pc <<EOF
prefix=/usr/local
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: Lua
Description: Lua scripting language
Version: $VER
Libs: -L\${libdir} -llua -lm
Cflags: -I\${includedir}
EOF
$SU mkdir -p /usr/local/lib/pkgconfig
$SU cp lua5.5.pc /usr/local/lib/pkgconfig/lua5.5.pc
