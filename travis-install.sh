#!/bin/bash

case "$MARE_ARCH" in
    win-x64)
        sudo apt-get -qq update
        sudo apt-get install -y gcc-mingw-w64-x86-64
        ;;
    win-x86)
        sudo apt-get -qq update
        sudo apt-get install -y gcc-mingw-w64-i686
        ;;
esac
