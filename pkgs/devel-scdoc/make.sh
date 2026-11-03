SRC="${HDX_SRC:-/hdxp/src/devel-scdoc-src}"
TAG=1.11.4
COMMIT=70de0e5e5d3bc40134ee65c35f1631656199f4be
[ -d "$SRC/.git" ] || git clone https://git.sr.ht/~sircmpwn/scdoc "$SRC"
cd "$SRC"
git checkout -q "$TAG"
# a tag can be moved, a commit hash cannot
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "error: tag $TAG is not commit $COMMIT"; exit 1; }
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
make -j"$(nproc 2>/dev/null || echo 1)" PREFIX=/usr/local
$SU make install PREFIX=/usr/local
