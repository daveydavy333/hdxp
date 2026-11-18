#!/bin/sh
set -eu
umask 022
PORT="${HDXP:-/hdxp}/pkgs/${HDX_PKG:-util-acpid}"
SRC="${HDX_SRC:-/hdxp/src/util-acpid-src}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 2)}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

need() { # need <pkg-config module> <min version>
    pkg-config --atleast-version="$2" "$1" 2>/dev/null || {
        echo "util-acpid: missing $1 >= $2 (have: $(pkg-config --modversion "$1" 2>/dev/null || echo none))" >&2
        exit 1
    }
}
# fetch <url> <file> <sha256>; an empty sha means "unpinned": print it and stop,
# unless HDX_TOFU=1 (then trust this first download)
fetch() {
    [ -f "$2" ] || curl -fL -o "$2" "$1"
    if [ -z "$3" ]; then
        echo "util-acpid: UNPINNED $2 sha256=$(sha256sum "$2" | cut -d' ' -f1)" >&2
        [ "${HDX_TOFU:-0}" = 1 ] || { echo "util-acpid: re-run with HDX_TOFU=1 to accept, then pin this sha in make.sh" >&2; exit 1; }
        return 0
    fi
    echo "$3  $2" | sha256sum -c - >/dev/null || { echo "util-acpid: checksum mismatch for $2" >&2; rm -f "$2"; exit 1; }
}
mkdir -p "$SRC"
cd "$SRC"

VER=2.0.34
fetch "https://github.com/tedfelix/acpid2/archive/refs/tags/$VER.tar.gz" \
    "acpid-$VER.tar.gz" de62f559b4e434a128d05b69df55f5eb2a3c184c930d536cf0db2496c7a2fb2e
rm -rf "acpid2-$VER"
tar xzf "acpid-$VER.tar.gz"
cd "acpid2-$VER"

# no autotools in hdxp: write the config.h that configure would have made
cat > config.h <<EOT
#define PACKAGE "acpid"
#define VERSION "$VER"
#define HAVE_FCHOWN 1
#define HAVE_CHMOD 1
#define HAVE_FSTAT 1
#define HAVE_FSTATAT 1
#define HAVE_OPENAT 1
#define HAVE_ASPRINTF 1
EOT
# musl has no isfdtype(): sock.c carries a fallback, only define HAVE_ISFDTYPE when libc has it
printf '#define _GNU_SOURCE\n#include <sys/socket.h>\nint main(void){return isfdtype(0,0);}\n' > probe.c
if ${CC:-cc} -o probe probe.c 2>/dev/null; then echo '#define HAVE_ISFDTYPE 1' >> config.h; fi

CF="${CFLAGS:--O2} -D_GNU_SOURCE -D_LARGEFILE64_SOURCE -include ./config.h"
${CC:-cc} $CF -o acpid acpid.c acpi_ids.c connection_list.c event.c input_layer.c \
    inotify_handler.c libnetlink.c log.c netlink.c proc.c sock.c ud_socket.c
${CC:-cc} $CF -o acpi_listen acpi_listen.c log.c ud_socket.c

$SU mkdir -p /usr/local/sbin /usr/local/bin /usr/local/share/man/man8 /etc/acpi/events
$SU install -m755 acpid /usr/local/sbin/acpid
$SU install -m755 acpi_listen /usr/local/bin/acpi_listen
$SU install -m644 acpid.8 acpi_listen.8 /usr/local/share/man/man8/
sync
