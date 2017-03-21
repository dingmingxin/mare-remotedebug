#!/bin/bash

git clone --depth 1 https://github.com/muzuiget/mirror-lua.git lua-src
echo $TARGET_ARCH
cd lua-src
if [[ $TARGET_ARCH == 'macosx-x64' ]]; then
    make macosx
    cd ..
    gcc -O2 -bundle -undefined dynamic_lookup -I./lua-src/src -o remotedebug.so remotedebug.c
else
    make linux
    cd ..
    gcc -O2 -shared -fPIC -D_GNU_SOURCE -I./lua-src/src -o remotedebug.so remotedebug.c
fi

ls
cp lua-src/src/lua .
./lua -e 'print(require("remotedebug"))'
