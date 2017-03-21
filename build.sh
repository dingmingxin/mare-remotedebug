#!/bin/bash

function download_android_ndk() {
    ndk=android-ndk-r13b
    pkg=$ndk-linux-x86_64.zip
    url="https://dl.google.com/android/repository/$pkg"
    if [ ! -d android-ndk ]; then
        if [ ! -f $pkg ]; then
            wget $url -O $pkg
        fi
        unzip $pkg
        mv $ndk android-ndk
    fi
}

function clone_lua_src() {
    url=https://github.com/muzuiget/mirror-lua.git
    commit=v5.3.4
    if [ ! -d lua-src ]; then
        git clone --depth 1 --single-branch --branch $commit $url lua-src
    else
        cd lua-src
        git co . && git clean -dfx .
        cd ..
    fi
}

function create_android_toolchain() {
    download_android_ndk

    arch=$1
    api=21
    ./android-ndk/build/tools/make_standalone_toolchain.py \
        --arch $arch \
        --api $api \
        --install-dir android-toolchain
}

function build_linux() {
    cflags="$1"

    cd lua-src
    make linux \
        CC="gcc -std=gnu99 $cflags"
    cd ..

    gcc -O2 -shared -fPIC -D_GNU_SOURCE $cflags \
        -I./lua-src/src \
        -o remotedebug.so remotedebug.c

    ./lua-src/src/lua -e 'print(require("remotedebug"))'
}

function build_win() {
    toolchain=$1
    cflags="$2"

    cd lua-src
    make mingw \
        CC="$toolchain-gcc -std=gnu99 $cflags" \
        AR="$toolchain-ar rcu" \
        RANLIB="$toolchain-ranlib"
    cd ..

    ${toolchain}-gcc -O2 -shared $cflags \
        -I./lua-src/src \
        -o remotedebug.dll remotedebug.c \
        -L./lua-src/src -llua53

    ls remotedebug.dll
}

function build_android() {
    toolchain=$1
    cflags="-DLUA_32BITS $2"

    export PATH=`pwd`/android-toolchain/bin:$PATH

    cd lua-src
    make generic \
        CC="$toolchain-gcc -std=gnu99 $cflags" \
        AR="$toolchain-ar rcu" \
        RANLIB="$toolchain-ranlib" \
        SYSCFLAGS="-DLUA_USE_POSIX -DLUA_USE_DLOPEN" \
        SYSLIBS='-Wl,-E -pie -fPIE -ldl -lm'
    cd ..

    ${toolchain}-gcc -O2 -shared -fPIC -D_GNU_SOURCE $cflags \
        -I./lua-src/src \
        -o remotedebug.so remotedebug.c

    ls remotedebug.so
}

function build_mac_x64() {
    cd lua-src
    make macosx
    cd ..

    gcc -O2 -bundle -undefined dynamic_lookup \
        -I./lua-src/src \
        -o remotedebug.so remotedebug.c

    ./lua-src/src/lua -e 'print(require("remotedebug"))'
}

clone_lua_src
case "$MARE_ARCH" in
    linux-x64)
        build_linux '-m64'
        ;;
    linux-x86)
        build_linux '-m32'
        ;;
    mac-x64)
        build_mac_x64
        ;;
    win-x64)
        build_win x86_64-w64-mingw32
        ;;
    win-x86)
        build_win i686-w64-mingw32 '-static-libgcc'
        ;;
    android-x64)
        create_android_toolchain x86_64
        build_android x86_64-linux-android
        ;;
    android-x86)
        create_android_toolchain x86
        build_android i686-linux-android
        ;;
    android-arm)
        create_android_toolchain arm
        build_android arm-linux-androideabi
        ;;
    android-arm64)
        create_android_toolchain arm64
        build_android aarch64-linux-android
        ;;
    android-mips)
        create_android_toolchain mips
        build_android mipsel-linux-android
        ;;
    android-mips64)
        create_android_toolchain mips64
        build_android mips64el-linux-android
        ;;
    *)
        echo 'Error: invalid MARE_ARCH value' && exit 1
        ;;
esac
