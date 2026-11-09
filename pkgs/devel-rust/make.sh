SRC="${HDX_SRC:-/hdxp/src/devel-rust-src}"
VER=1.99.0
# fill in: curl -fsSL https://static.rust-lang.org/dist/rust-1.99.0-x86_64-unknown-linux-musl.tar.xz | sha256sum
SHA256=0ed5ec213fbde7cd720054d4a7eabd592822e73ce406da0aea57e7b1b48e8b0f
TRIPLE=x86_64-unknown-linux-musl
TARBALL="rust-$VER-$TRIPLE.tar.xz"
mkdir -p "$SRC"
cd "$SRC"
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://static.rust-lang.org/dist/$TARBALL"
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "rust-$VER-$TRIPLE" ] || tar -xf "$TARBALL"
cd "rust-$VER-$TRIPLE"
# install only the compiler, cargo and the target's std (no docs, clippy, rustfmt, analyzer)
for c in rustc cargo "rust-std-$TRIPLE"; do
  grep -qx "$c" components || { echo "component $c not found in $TARBALL, components are:"; cat components; exit 1; }
done
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU ./install.sh --prefix=/usr/local --components="rustc,cargo,rust-std-$TRIPLE" --disable-ldconfig
# smoke test: compile and run a program, so a missing library or linker problem shows up now
T="$(mktemp -d)"
printf 'fn main() { println!("rust ok"); }\n' > "$T/hello.rs"
/usr/local/bin/rustc --version
/usr/local/bin/cargo --version
/usr/local/bin/rustc -o "$T/hello" "$T/hello.rs" && "$T/hello"
rc=$?
rm -rf "$T"
[ "$rc" -eq 0 ] || { echo "rust smoke test failed"; exit 1; }
