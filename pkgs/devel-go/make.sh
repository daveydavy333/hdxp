# official prebuilt Go toolchain tarball (static binaries, runs on musl). sha256 values are the ones
# published for go1.26.2 on go.dev/dl (taken from a third-party pin table): sha256sum -c fails loudly if wrong
SRC="${HDX_SRC:-/hdxp/src/devel-go-src}"
VER=1.26.2
case "$(uname -m)" in
  x86_64)  ARCH=amd64; SHA256=990e6b4bbba816dc3ee129eaeaf4b42f17c2800b88a2166c265ac1a200262282 ;;
  aarch64) ARCH=arm64; SHA256=c958a1fe1b361391db163a485e21f5f228142d6f8b584f6bef89b26f66dc5b23 ;;
  *) echo "devel-go: unsupported architecture $(uname -m)" >&2; exit 1 ;;
esac
TARBALL="go$VER.linux-$ARCH.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://go.dev/dl/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d go ] || tar xf "$TARBALL"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU rm -rf /usr/local/go
$SU cp -R go /usr/local/go
$SU mkdir -p /usr/local/bin
$SU ln -sf ../go/bin/go /usr/local/bin/go
$SU ln -sf ../go/bin/gofmt /usr/local/bin/gofmt
sync
/usr/local/bin/go version
