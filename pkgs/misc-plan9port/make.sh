COMMIT=1f1396913fb5372408f442ed26933f5ae4b399cd
SRC="${HDX_SRC:-/hdxp/src/misc-plan9port-src}"
DEST=/usr/local/plan9

if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi

# fetch exactly the pinned commit (shallow)
mkdir -p "$SRC/plan9port"
cd "$SRC/plan9port"
if [ ! -d .git ]; then
    git init -q
    git remote add origin https://github.com/9fans/plan9port
    git fetch -q --depth 1 origin "$COMMIT"
    git checkout -q FETCH_HEAD
fi
[ "$(git rev-parse HEAD)" = "$COMMIT" ] || { echo "plan9port: checked out commit does not match the pin"; exit 1; }

# host compiler settings; gcc 15 defaults to C23, which this code predates.
# the graphical programs (acme, sam, rio...) need the X11 headers, so without them build without X11
{
    echo "CC9=gcc"
    echo "CC9FLAGS='-std=gnu17'"
    [ -f /usr/include/X11/Xlib.h ] || echo "WSYSTYPE=nowsys"
} > LOCAL.config

# step 1: build in the source tree
./INSTALL -b

# step 2: move the tree to its final place and finish the install there
$SU rm -rf "$DEST"
$SU mkdir -p "$DEST"
$SU cp -a "$SRC/plan9port/." "$DEST/"
$SU rm -rf "$DEST/.git"
cd "$DEST"
$SU ./INSTALL -c

# `9 <command>` runs any plan 9 command without putting the whole tree in PATH
$SU mkdir -p /usr/local/bin
$SU ln -sf "$DEST/bin/9" /usr/local/bin/9

echo "plan9port installed in $DEST. try: 9 rc"
