#!/bin/bash
set -e

##
# Pre-requirements:
# - env TARGET: path to target work dir
# - env OUT: path to directory where artifacts are stored
# - env CC, CXX, FLAGS, LIBS, etc...
##

if [ ! -d "$TARGET/repo" ]; then
    echo "fetch.sh must be executed first."
    exit 1
fi

# build the libpng library
cd "$TARGET/repo"
autoreconf -f -i
./configure --with-libpng-prefix=MAGMA_ --disable-shared LDFLAGS="$LDFLAGS" CFLAGS="$CFLAGS"
make -j$(nproc) clean
make -j$(nproc) libpng16.la

cp .libs/libpng16.a "$OUT/"

# build libpng_read_fuzzer.
ABORT_LINE=$(grep -n 'extern "C" int LLVMFuzzerTestOneInput' contrib/oss-fuzz/libpng_read_fuzzer.cc | cut -d: -f1)
echo 'libpng_read_fuzzer.cc:'$ABORT_LINE > $TARGET/BBEntry.txt
$CXX $CXXFLAGS -std=c++14 -I. \
     contrib/oss-fuzz/libpng_read_fuzzer.cc \
     -o $OUT/libpng_read_fuzzer \
     $LDFLAGS .libs/libpng16.a $LIBS -lz