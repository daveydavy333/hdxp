#!/bin/sh
set -eu
umask 022
SRC="${HDX_SRC:-/hdxp/src/util-monolith-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() { # need <pkg-config module> <min version>
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "util-monolith: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
fetch() { # fetch <url> <file> <sha256>
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "util-monolith: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}

VER=0.1.0
mkdir -p "$SRC"
cd "$SRC"
fetch "https://github.com/daveydavy333/MONOLITH/archive/refs/tags/v$VER.tar.gz" \
    "monolith-$VER.tar.gz" 9b11c23c38f4752e163d0aaecd6490345a390b0f1b5a513903c2855135da7684

need wlroots-0.20 0.20.1
need wayland-server 1.22.90
need wayland-protocols 1.39
need libinput 1.26
need xkbcommon 0
need libdrm 0
need pixman-1 0

# GitHub names the top folder after the repo and tag; unpack into our own folder instead
rm -rf "monolith-$VER"
mkdir "monolith-$VER"
tar xzf "monolith-$VER.tar.gz" --strip-components=1 -C "monolith-$VER"
cd "monolith-$VER"

# --wrap-mode=nofallback: never let meson download anything
meson setup build \
    --prefix=/usr/local --sysconfdir=/etc --libdir=lib \
    --buildtype=release --wrap-mode=nofallback
meson compile -C build -j "$JOBS"
$SU env DESTDIR= meson install -C build
sync
