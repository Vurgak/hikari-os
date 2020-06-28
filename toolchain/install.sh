#!/usr/bin/env bash

set -e

export TARGET=x86_64-elf

SCRIPT_PATH=$(readlink -f $(dirname "$0"))
export PREFIX=$SCRIPT_PATH/x86_64-elf

export PATH="$PREFIX/bin:$PATH"

BINUTILS_VERSION=2.34
GCC_VERSION=10.1.0

CPU_CORES=$(cat /proc/cpuinfo | grep "cpu cores" | head -1 | awk -F ' ' '{print $4}')
[ -z "$JOBS" ] && JOBS=$(expr $CPU_CORES - 1)

cd $SCRIPT_PATH

if [ ! -f binutils-$BINUTILS_VERSION.tar.gz ]; then
	wget https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.gz
fi

if [ ! -f gcc-$GCC_VERSION.tar.gz ]; then
	wget https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.gz
fi

if [ $NO_PIGZ ]
then
    echo -n Unpacking Binutils
    tar --checkpoint=.1000 -xf binutils-$BINUTILS_VERSION.tar.gz
    echo

    echo -n Unpacking GCC
    tar --checkpoint=.1000 -xf gcc-$GCC_VERSION.tar.gz
    echo
else
    echo -n Unpacking Binutils
    tar --checkpoint=.1000 -I pigz -xf binutils-$BINUTILS_VERSION.tar.gz
    echo

    echo -n Unpacking GCC
    tar --checkpoint=.1000 -I pigz -xf gcc-$GCC_VERSION.tar.gz
    echo
fi

mkdir -p build-binutils
pushd build-binutils
    ../binutils-$BINUTILS_VERSION/configure --prefix=$PREFIX --target=$TARGET \
        --with-sysroot --disable-nls --disable-werror
    make -j $JOBS
    make install
popd

mkdir -p build-gcc
pushd build-gcc
    ../gcc-$GCC_VERSION/configure --target=$TARGET --prefix="$PREFIX" \
        --disable-nls --enable-languages=c --without-headers
    make all-gcc -j $JOBS
    make all-target-libgcc -j $JOBS
    make install-gcc
    make install-target-libgcc
popd

rm -rf build-binutils
rm -rf build-gcc

echo $PREFIX
