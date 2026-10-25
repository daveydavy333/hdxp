SRC="${HDX_SRC:-/hdxp/src/devel-python3-src}"
VER=3.14.9
SHA256=79bda7368e7ac571cc4a0e4048bcfbc6a2765fd037ee282ffdb3dba7e6224d97
TARBALL="cpython-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/python/cpython/archive/refs/tags/v$VER.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "cpython-$VER" ] || tar xzf "$TARBALL"
cd "cpython-$VER"
CPPFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib" \
  ./configure --prefix=/usr/local --enable-shared --with-ensurepip=no --with-system-expat --disable-test-modules
make -j"$(nproc 2>/dev/null || echo 1)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
$SU ln -sf python3 /usr/local/bin/python
