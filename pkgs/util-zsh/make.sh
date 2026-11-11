set -e
SRC="${HDX_SRC:-/hdxp/src/util-zsh-src}"
VER=5.9.2
SHA256=bc6737138e68aba0647b4f776a8e2785c750fb545af6e6a7d6d554e72d1b4c37
TARBALL="zsh-$VER.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
# Ubuntu's orig tarball; upstream also publishes https://www.zsh.org/pub/zsh-$VER.tar.xz
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://archive.ubuntu.com/ubuntu/pool/main/z/zsh/zsh_$VER.orig.tar.xz"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "zsh-$VER" ] || tar -xf "$TARBALL"
cd "zsh-$VER"
make distclean >/dev/null 2>&1 || true
# No pcre (the zsh/pcre module is skipped), no libcap, no gdbm.
# Global rc files live in /usr/local/etc/zsh. Modules stay dynamic.
CPPFLAGS="${CPPFLAGS:-} -I/usr/local/include -I/usr/local/include/ncursesw" \
LDFLAGS="${LDFLAGS:-} -L/usr/local/lib" \
./configure --prefix=/usr/local --enable-etcdir=/usr/local/etc/zsh \
  --enable-multibyte --enable-function-subdirs --with-tcsetpgrp \
  --disable-pcre --disable-cap --disable-gdbm
make -j"$(nproc)"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
$SU make install.man

# Register as a login shell
grep -qx /usr/local/bin/zsh /etc/shells 2>/dev/null || echo /usr/local/bin/zsh | $SU tee -a /etc/shells >/dev/null

/usr/local/bin/zsh -fc 'echo "zsh $ZSH_VERSION installed"'
