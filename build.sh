#!/bin/bash

function clone_lua_src() {
    url=https://github.com/muzuiget/mirror-lua.git
    commit=v5.3.4
    git clone --depth 1 --single-branch --branch $commit $url lua-src
}

function build_linux() {
    cflags="$1"

    cd lua-src
    make linux \
        CC="gcc -std=gnu99 $cflags"
    cd ..

    gcc -O2 -shared -fPIC -D_GNU_SOURCE \
        $cflags \
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

function build_mac_x64() {
    cd lua-src
    make macosx
    cd ..

    gcc -O2 -bundle -undefined dynamic_lookup \
        -I./lua-src/src \
        -o remotedebug.so remotedebug.c

    ./lua-src/src/lua -e 'print(require("remotedebug"))'
}

pwd
git clean -dffx .
clone_lua_src
case "$MARE_ARCH" in
    linux-x64)
        build_linux '-m64'
        ;;
    linux-x86)
        build_linux '-m32'
        ;;
    win-x64)
        build_win x86_64-w64-mingw32
        ;;
    win-x86)
        build_win i686-w64-mingw32 '-static-libgcc'
        ;;
    mac-x64)
        build_mac_x64
        ;;
    *)
        echo 'Error: invalid MARE_ARCH value' && exit 1
        ;;
esac
