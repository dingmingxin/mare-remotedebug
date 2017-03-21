#!/bin/bash

git clone --depth 1 https://github.com/muzuiget/mirror-lua.git lua-src
echo $MARE_TARGET
cd lua-src/src
if [ $MARE_TARGET = 'macos-x64' ]; then
    make macosx
    cd ../..
    gcc -O2 -bundle -undefined dynamic_lookup -I./lua-src/src -o remotedebug.so remotedebug.c
elif [ $MARE_TARGET = 'win-x64' ]; then
    apt install gcc-mingw-w64-x86-64
    sed -i 's/^\(CC\|AR\|RANLIB\)= /\0x86_64-w64-mingw32-/g' Makefile
    make mingw
    cd ../..
    x86_64-w64-mingw32-gcc -O2 -shared \
        -I./lua-src/src \
        -o remotedebug.dll remotedebug.c \
        -L./lua-src/src -llua53
elif [ $MARE_TARGET = 'win-x86' ]; then
    apt install gcc-mingw-w64-i686
    sed -i 's/^\(CC\|AR\|RANLIB\)= /\0xi686-w64-mingw32-/g' Makefile
    make mingw
    cd ../..
    x86_64-w64-mingw32-gcc -O2 -shared \
        -I./lua-src/src \
        -o remotedebug.dll remotedebug.c \
        -L./lua-src/src -llua53
else
    make linux
    cd ..
    gcc -O2 -shared -fPIC -D_GNU_SOURCE -I./lua-src/src -o remotedebug.so remotedebug.c
fi

ls
cp lua-src/src/lua .
./lua -e 'print(require("remotedebug"))'
