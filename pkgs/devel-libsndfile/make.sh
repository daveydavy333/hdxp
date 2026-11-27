VER=1.2.2
SHA=ffe12ef8add3eaca876f04087734e6e8e029350082f3251f565fa9da55b52121
TAR="libsndfile-$VER.tar.gz"
SRC="${HDX_SRC:-/hdxp/src/devel-libsndfile-src}"
PKG="${HDX_PKG:-devel-libsndfile}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"
command -v cmake >/dev/null || { echo "error: cmake not found (devel-cmake)"; exit 1; }
JOBS=$(nproc 2>/dev/null || echo 1)

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://github.com/libsndfile/libsndfile/archive/refs/tags/$VER.tar.gz"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "libsndfile-$VER" ] || tar -xf "$TAR"
cd "libsndfile-$VER"

# no flac/vorbis/opus/mpeg: wav, aiff, au and the other plain formats are enough for pw-play and friends
rm -rf build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_SHARED_LIBS=ON -DBUILD_PROGRAMS=ON -DBUILD_EXAMPLES=OFF \
    -DBUILD_TESTING=OFF -DENABLE_EXTERNAL_LIBS=OFF -DENABLE_MPEG=OFF -DENABLE_CPACK=OFF
cmake --build build --parallel "$JOBS"
$SU cmake --install build
[ -s build/install_manifest.txt ] || { echo "error: no install manifest"; exit 1; }
$SU install -Dm644 build/install_manifest.txt "/usr/local/share/hdxp-manifests/$PKG.txt"
sync

for f in lib/libsndfile.so lib/pkgconfig/sndfile.pc bin/sndfile-info; do
    [ -s "/usr/local/$f" ] || { echo "error: /usr/local/$f is empty or missing"; exit 1; }
done
