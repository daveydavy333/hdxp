SRC="${HDX_SRC:-/hdxp/src/devel-cargo-c-src}"
VER=0.10.26
# check: curl -fsSL https://github.com/lu-zero/cargo-c/releases/download/v0.10.26/cargo-c-x86_64-unknown-linux-musl.tar.gz | sha256sum
SHA256=685fab5a2e1539c5075cea21c42469ee5a489d877dbdbf7adccf4bb631d77545
TARBALL="cargo-c-x86_64-unknown-linux-musl-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/lu-zero/cargo-c/releases/download/v$VER/cargo-c-x86_64-unknown-linux-musl.tar.gz"
echo "$SHA256  $TARBALL" | sha256sum -c -
if [ ! -d "cargo-c-$VER" ]; then
  mkdir "cargo-c-$VER"
  tar -xzf "$TARBALL" -C "cargo-c-$VER" || { rm -rf "cargo-c-$VER"; echo "extraction failed"; exit 1; }
fi
cd "cargo-c-$VER"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
for b in cargo-capi cargo-cbuild cargo-cinstall cargo-ctest; do
  [ -s "$b" ] || { echo "missing or empty $b"; exit 1; }
  $SU install -m 755 "$b" /usr/local/bin/"$b"
done
/usr/local/bin/cargo-cbuild --version || { echo "cargo-cbuild does not run"; exit 1; }
