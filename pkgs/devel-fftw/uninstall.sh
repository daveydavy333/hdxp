rm -f /usr/local/lib/libfftw3.* /usr/local/lib/libfftw3.la /usr/local/lib/pkgconfig/fftw3.pc
rm -f /usr/local/include/fftw3.h /usr/local/include/fftw3.f /usr/local/include/fftw3.f03 /usr/local/include/fftw3l.f03 /usr/local/include/fftw3q.f03
rm -f /usr/local/lib/cmake/fftw3/*
rmdir /usr/local/lib/cmake/fftw3 2>/dev/null || true
rm -f /usr/local/share/man/man1/fftw-wisdom.1 /usr/local/share/man/man1/fftw-wisdom-to-conf.1
