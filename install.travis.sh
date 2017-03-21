#!/bin/bash

case "$MARE_ARCH" in
    linux-x86)
        sudo apt-get -qq update
        sudo apt-get install -y libc6-dev-i386 lib32readline6-dev
        ;;
    win-x64)
        sudo apt-get -qq update
        sudo apt-get install -y gcc-mingw-w64-x86-64
        ;;
    win-x86)
        sudo apt-get -qq update
        sudo apt-get install -y gcc-mingw-w64-i686
        ;;
esac
