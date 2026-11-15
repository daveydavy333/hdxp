if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
$SU rm -f /usr/local/lib/libduktape.so* /usr/local/lib/libduktaped.so* /usr/local/lib/pkgconfig/duktape.pc \
          /usr/local/include/duktape.h /usr/local/include/duk_config.h
