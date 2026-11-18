#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-util-hack}"
SRC="${HDX_SRC:-/hdxp/src/util-hack-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
die() { echo "util-hack: $*" >&2; exit 1; }
need() {
    pkg-config --exists "$1" 2>/dev/null || die "missing pkg-config module $1"
}
mkdir -p "$SRC"
cd "$SRC"

# upstream has no releases: it builds whatever HACK_REV points at (default HEAD).
# Unpinned by default: the commit and sha256 it built are printed for pinning.
# To pin: set HACK_REV=<commit> and HACK_SHA=<sha256> below.
HACK_REV="${HACK_REV:-HEAD}"
HACK_SHA="${HACK_SHA:-}"
TAR="hack-$HACK_REV.tar.gz"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://git.sr.ht/~shrub900/hack/archive/$HACK_REV.tar.gz"
GOT=$(sha256sum "$TAR" | cut -d' ' -f1)
COMMIT=$(gzip -dc "$TAR" | head -c 4096 | grep -a -o 'comment=[0-9a-f]\{40\}' | head -1 | cut -d= -f2 || true)
echo "util-hack: commit=${COMMIT:-unknown} sha256=$GOT" >&2
if [ -n "$HACK_SHA" ]; then
    [ "$GOT" = "$HACK_SHA" ] || { rm -f "$TAR"; die "checksum mismatch for $TAR"; }
else
    echo "util-hack: building unpinned HEAD; pin HACK_REV/HACK_SHA to freeze it" >&2
fi

for m in wayland-client xkbcommon pixman-1 fontconfig freetype2; do need "$m"; done
find /usr /opt -name 'libwld.*' 2>/dev/null | grep -q . || die "libwld not found: hdx i devel-neuwld"

# plan9port: hack links its libraries and headers (lib9, libframe, libthread, ...)
if [ -z "${PLAN9:-}" ]; then
    L=$(find /usr /opt -name lib9.a 2>/dev/null | head -1)
    [ -n "$L" ] && PLAN9=$(dirname "$(dirname "$L")")
fi
[ -n "${PLAN9:-}" ] && [ -f "$PLAN9/lib/lib9.a" ] && [ -f "$PLAN9/include/u.h" ] \
    || die "plan9port not found (need lib/lib9.a and include/u.h); set PLAN9=/path or fix misc-plan9port"
echo "util-hack: using PLAN9=$PLAN9" >&2

rm -rf hack-build
mkdir hack-build
tar xzf "$TAR" -C hack-build --strip-components=1
cd hack-build

# the Makefile hardcodes clang and libdrm_intel/libdrm_nouveau (not in hdxp); libcrypto stays (acme/sha1.c);
# override LIBS and build only the editor, not acme/mail/Mail
LIBS="-Wl,--start-group -lplumb -l9pclient -lmux -lcomplete -lbio -lframe -lthread -l9 -Wl,--end-group \
 -lwld -ldrm $(pkg-config --libs wayland-client xkbcommon pixman-1 fontconfig freetype2) \
 -lcrypto -lpthread -lm -lrt"
make -j "$JOBS" hack CC="${CC:-cc} -std=gnu17" PLAN9="$PLAN9" LIBS="$LIBS"

$SU mkdir -p /usr/local/bin
$SU install -m755 hack /usr/local/bin/hack
sync
cat >&2 <<EONOTE
util-hack: installed /usr/local/bin/hack
 run it with plan9port's tools on PATH:
   export PLAN9=$PLAN9 PATH=\$PATH:$PLAN9/bin
EONOTE
