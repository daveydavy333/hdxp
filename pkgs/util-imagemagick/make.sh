set -e
SRC="${HDX_SRC:-/hdxp/src/util-imagemagick-src}"
VER=7.1.2-35
SHA256=40b6fefa88fe16ca5a4b3d3db5133eaebfb0157f21f98530bde8aec5dd5b0776
TARBALL="ImageMagick-$VER.tar.gz"
mkdir -p "$SRC"
cd "$SRC"
# GitHub tag tarball: tags are permanent, unlike imagemagick.org/archive/releases,
# which prunes old versions. It unpacks to ImageMagick-$VER/.
[ -f "$TARBALL" ] || curl -fL -o "$TARBALL" "https://github.com/ImageMagick/ImageMagick/archive/refs/tags/$VER.tar.gz"
if [ "$SHA256" = FILL_ME ]; then
  sha256sum "$TARBALL"
  echo "pin the SHA256 above in make.sh, then run it again" >&2
  exit 1
fi
echo "$SHA256  $TARBALL" | sha256sum -c -
[ -d "ImageMagick-$VER" ] || tar -xf "$TARBALL"
cd "ImageMagick-$VER"

# Lean build: PNG, JPEG, WebP, freetype/fontconfig text, lcms, xml.
# Q8 without HDRI keeps memory use and build time down on the small machines.
# No modules, no X11, no perl, no C++ API, no OpenMP.
make distclean >/dev/null 2>&1 || true
./configure --prefix=/usr/local \
  --disable-docs --disable-openmp --disable-opencl --disable-static --enable-shared \
  --disable-hdri --with-quantum-depth=8 \
  --without-modules --without-x --without-perl --without-magick-plus-plus \
  --with-png=yes --with-jpeg=yes --with-webp=yes \
  --with-freetype=yes --with-fontconfig=yes --with-lcms=yes --with-xml=yes --with-zlib=yes \
  --without-tiff --without-bzlib --without-lzma --without-zstd --without-zip \
  --without-openjp2 --without-heic --without-jxl --without-raw --without-openexr \
  --without-wmf --without-lqr --without-raqm --without-pango --without-rsvg \
  --without-fftw --without-djvu --without-jbig --without-gslib --without-gvc \
  --without-autotrace --without-fpx --without-dps
make -j"$(nproc)"

if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU make install
# ImageMagick 7 dispatches on the program name, so the old tool names
# can simply be links to magick.
$SU sh -c 'cd /usr/local/bin && for t in convert identify mogrify composite montage compare; do ln -sf magick "$t"; done'

# Quick sanity check of the formats we care about
/usr/local/bin/magick -version | head -n 3 || true
/usr/local/bin/magick -list format | grep -E '^ +(PNG|JPEG|WEBP) ' || true
