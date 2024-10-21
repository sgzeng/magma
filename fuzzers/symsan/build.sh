#!/bin/bash
set -xe

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
##

if [ ! -d "$FUZZER/afl" ] || [ ! -d "$FUZZER/symsan" ]; then
    echo "fetch.sh must be executed first."
    exit 1
fi

# build AFL
(
    cd "$FUZZER/afl"
    CC=clang-12 make -j $(nproc)
    CC=clang-12 make -j $(nproc) -C llvm_mode
)

# build Z3
# (
#    cd "$FUZZER/z3"
#    mkdir -p build install cmake_conf
#    cd build
#    CXX=clang++ CC=clang cmake ../ \
#        -DCMAKE_INSTALL_PREFIX="$FUZZER/z3/install" \
#        -DCMAKE_INSTALL_Z3_CMAKE_PACKAGE_DIR="$FUZZER/z3/cmake_conf"
#    make -j $(nproc)
#    make install
#    export PATH="$FUZZER/z3/install/bin:$PATH"
# )

# # build SymSan
(
    cd "$FUZZER/symsan"
    CC=clang-12 CXX=clang++-12 cmake -DCMAKE_INSTALL_PREFIX=. \
    ./ && make -j && make install
)


# prepare output dirs
mkdir -p "$OUT/"{afl,symsantrack,symsanfast}

# compile afl_driver.cpp
"$FUZZER/afl/afl-clang-fast++" $CXXFLAGS -std=c++14 -c -fPIC \
    "$FUZZER/afl/afl_driver.cpp" -o "$OUT/afl/afl_driver.o"

export KO_CC=clang-12
export KO_CXX=clang++-12
export CC="$FUZZER/symsan/bin/ko-clang" 
export CXX="$FUZZER/symsan/bin/ko-clang++" 

USE_TRACK=1 $CXX -std=c++14 -c -fPIC \
    "$FUZZER/afl/afl_driver.cpp" -o "$OUT/symsantrack/afl_driver.o"

$CXX $CXXFLAGS -std=c++14 -c -fPIC \
    "$FUZZER/afl/afl_driver.cpp" -o "$OUT/symsanfast/afl_driver.o"
