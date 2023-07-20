#!/usr/bin/env sh
#
export PATH="$(pwd)/bin:$PATH"
ulimit -n 1024




ROOT=$(pwd)

ARCH=x86_64
TARGET=$ARCH-linux-gnu
TARGET_TOOL_PREFIX=$ROOT/install/bin/$TARGET

BINUTILS_BUILD=binutils_build
GCC_BUILD=gcc_build
GLIBC_BUILD=glibc_build
HOMEBREW_ROOT=/opt/homebrew/Cellar

BINUTILS_ROOT=$ROOT/install/x86_64-linux-gnu/bin

export LD_LIBRARY_PATH=$HOMEBREW_ROOT/gmp/6.2.1_1/lib:$HOMEBREW_ROOT/mpfr/4.2.0-p9/lib:$HOMEBREW_ROOT/zstd/1.5.5/lib:$HOMEBREW_ROOT/zlib/lib:$HOMEBREW_ROOT/libmpc/1.3.1/lib:$HOMEBREW_ROOT/isl/0.26/lib

build_binutils()
{
    cd $ROOT
    if [[ -d $BINUTILS_BUILD ]]
    then
        rm -rf $BINUTILS_BUILD
    fi
    
    mkdir $BINUTILS_BUILD && cd $BINUTILS_BUILD
    CC=gcc-12 CXX=g++-12 ../binutils-2.40/configure \
        --prefix=$ROOT/install \
        --build=$(uname -m) \
        --host=$(uname -m) \
        --target=$TARGET \
        --with-arch=$ARCH \
        --with-fpu=vfp \
        --with-float=hard \
        --with-gmp=$HOMEBREW_ROOT/gmp/6.2.1_1 \
        --with-mpfr=$HOMEBREW_ROOT/mpfr/4.2.0-p9 \
        --with-zstd=$HOMEBREW_ROOT/zstd/1.5.5 \
        --with-zlib=$HOMEBREW_ROOT/zlib \
        --with-mpc=$HOMEBREW_ROOT/libmpc/1.3.1 \
        --with-isl=$HOMEBREW_ROOT/isl/0.26 \
        --with-lib-path=$ROOT/$TARGET/sys-root/usr/lib \
        --enable-ld \
        --disable-shared \
        --disable-nls \
        --disable-bootstrap \
        --disable-multilib \
        --disable-libquadmath \
        --disable-libquadmath-support \
        --disable-gprofng
    make CC=gcc-12 CXX=g++-12 
    make CC=gcc-12 CXX=g++-12 install -j12
}

build_gcc_stage1()
{
    cd $ROOT

    if [[ -d $GCC_BUILD ]]
    then
        rm -rf $GCC_BUILD
    fi

export AR_FOR_TARGET=$BINUTILS_ROOT/ar
export LD_FOR_TARGET=$BINUTILS_ROOT/ld
export OBJDUMP_FOR_TARGET=$BINUTILS_ROOT/objdump
export NM_FOR_TARGET=$BINUTILS_ROOT/nm
export RANLIB_FOR_TARGET=$BINUTILS_ROOT/ranlib
export READELF_FOR_TARGET=$BINUTILS_ROOT/readelf
export STRIP_FOR_TARGET=$BINUTILS_ROOT/strip
export AS_FOR_TARGET=$BINUTILS_ROOT/as


    mkdir $GCC_BUILD && cd $GCC_BUILD
    CC=gcc-12 CXX=g++-12 ../gcc-12.3.0/configure \
        --prefix=$ROOT/install \
        --with-sysroot=$ROOT/$TARGET/sys-root \
        --build=$(uname -m) \
        --host=$(uname -m) \
        --target=$TARGET \
        --with-arch=x86-64 \
        --disable-libatomic \
        --disable-libssp \
        --disable-libgomp \
        --disable-multilib \
        --disable-threads \
        --disable-libquadmath \
        --disable-libquadmath-support \
        --disable-libitm \
        --disable-libstdcxx \
        --disable-libsanitizer \
        --disable-libvtv \
        --disable-shared \
        --disable-bootstrap \
        --without-headers \
        --with-newlib \
        --disable-nls \
        --with-gmp=$HOMEBREW_ROOT/gmp/6.2.1_1 \
        --with-mpfr=$HOMEBREW_ROOT/mpfr/4.2.0-p9 \
        --with-zstd=$HOMEBREW_ROOT/zstd/1.5.5 \
        --with-zlib=$HOMEBREW_ROOT/zlib \
        --with-mpc=$HOMEBREW_ROOT/libmpc/1.3.1 \
        --with-isl=$HOMEBREW_ROOT/isl/0.26 \
        --with-libiconv-prefix=$HOMEBREW_ROOT/libiconv \
        --with-libintl-prefix=$HOMEBREW_ROOT/gettext \
        --enable-languages=c,c++ 
    make CC=gcc-12 CXX=g++-12 -j12   all-gcc
    make CC=gcc-12 CXX=g++-12 install-gcc
}

build_glibc()
{
    cd $ROOT

    if [[ -d $GLIBC_BUILD ]]
    then
        rm -rf $GLIBC_BUILD
    fi


    mkdir $GLIBC_BUILD && cd $GLIBC_BUILD
    CC=$TARGET_TOOL_PREFIX-gcc \
    CXX=$TARGET_TOOL_PREFIX-g++ \
    LD=$TARGET_TOOL_PREFIX-ld \
    AR=$TARGET_TOOL_PREFIX-ar \
    RANLIB=$TARGET_TOOL_PREFIX-ranlib \
    ../glibc-2.37/configure \
        --prefix=/usr \
        --build=$(uname -m) \
        --host=$TARGET \
        --target=$TARGET \
        --with-headers=$ROOT/$TARGET/sys-root/usr/include \
        --disable-multilib \
        --disable-lipquadmath \
        --disable-libquadmath-support \
        --disable-libitm \
        --disable-profile \
        --with-fpu=vfp \
        --with-float=hard \
        --with-gmp=$HOMEBREW_ROOT/gmp/6.2.1_1 \
        --with-zstd=$HOMEBREW_ROOT/zstd/1.5.5 \
        --with-zlib=$HOMEBREW_ROOT/zlib \
        --with-libiconv-prefix=$HOMEBREW_ROOT/libiconv \
        libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes libc_cv_gnu89_inline=yes \
        --disable-werror 

    make \
        install_root=$ROOT/$TARGET/sys-root \
        install-bootstrap-headers=yes \
        install-headers


    make \
        csu/subdir_lib


    if [[ ! -d $ROOT/$TARGET/sys-root/usr/lib ]]
    then
        mkdir $ROOT/$TARGET/sys-root/usr/lib
    fi

    install csu/crt1.o csu/crti.o csu/crtn.o $ROOT/$TARGET/sys-root/usr/lib
}

build_rest1()
{
    $TARGET_TOOL_PREFIX-gcc \
        -nostdlib \
        -nostartfiles \
        -shared \
        -x c /dev/null \
        -o $ROOT/$TARGET/sys-root/usr/lib/libc.so

    local GNU_DIR=$ROOT/$TARGET/sys-root/usr/include/gnu

    if [[ ! -d $GNU_DIR ]]
    then
        mkdir $GNU_DIR
    fi

    touch $ROOT/$TARGET/sys-root/usr/include/gnu/stubs.h


    cd $ROOT/$GCC_BUILD
    make -j12 all-target-libgcc
    make install-target-libgcc


}

build_rest2()
{
    cd $ROOT/$GLIBC_BUILD
    make -j12
    make \
        install_root=$ROOT/$TARGET/sys-root \
        install


}
build_rest3()
{

    cd $ROOT/$GCC_BUILD
    make -j12
    make install
}

build_gcc_stage2()
{
    cd $ROOT

    local GCC_BUILD_2=gcc_build_2

    if [[ -d $GCC_BUILD_2 ]]
    then
        rm -rf $GCC_BUILD_2
    fi

export AR_FOR_TARGET=$BINUTILS_ROOT/ar
export LD_FOR_TARGET=$BINUTILS_ROOT/ld
export OBJDUMP_FOR_TARGET=$BINUTILS_ROOT/objdump
export NM_FOR_TARGET=$BINUTILS_ROOT/nm
export RANLIB_FOR_TARGET=$BINUTILS_ROOT/ranlib
export READELF_FOR_TARGET=$BINUTILS_ROOT/readelf
export STRIP_FOR_TARGET=$BINUTILS_ROOT/strip
export AS_FOR_TARGET=$BINUTILS_ROOT/as
    
    mkdir $GCC_BUILD_2 && cd $GCC_BUILD_2
    CC=gcc-12 CXX=g++-12 ../gcc-12.3.0/configure \
        --prefix=$ROOT/install2 \
        --with-sysroot=$ROOT/$TARGET/sys-root \
        --build=$(uname -m) \
        --host=$(uname -m) \
        --target=$TARGET \
        --with-arch=x86-64 \
        --enable-libatomic \
        --enable-shared \
        --disable-bootstrap \
        --disable-nls \
        --disable-multilib \
        --with-gmp=$HOMEBREW_ROOT/gmp/6.2.1_1 \
        --with-mpfr=$HOMEBREW_ROOT/mpfr/4.2.0-p9 \
        --with-zstd=$HOMEBREW_ROOT/zstd/1.5.5 \
        --with-zlib=$HOMEBREW_ROOT/zlib \
        --with-mpc=$HOMEBREW_ROOT/libmpc/1.3.1 \
        --with-isl=$HOMEBREW_ROOT/isl/0.26 \
        --with-libiconv-prefix=$HOMEBREW_ROOT/libiconv \
        --with-libintl-prefix=$HOMEBREW_ROOT/gettext \
        --enable-languages=c,c++

    make CC=gcc-12 CXX=g++-12 -j12
    make CC=gcc-12 CXX=g++-12 install
}

## the following order should be followed
#build_binutils
#build_gcc_stage1
#build_glibc
#build_rest1
#build_rest2
#build_rest3
build_gcc_stage2
