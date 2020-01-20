#!/usr/bin/env bash

# Color
red="\033[1;31m"
yellow="\033[1;33m"
green="\033[1;32m"
echo -e "$green"

# environtment
KERNEL_DIR=$PWD
KERNEL_OUT=$pwd/out/arch/arm64/boot/Image.gz-dtb
CONFIG=$pwd/mystic-tulip_defconfig
CORE="$(grep -c '^processor' /proc/cpuinfo)"
CCACHE="$(command -v ccache)"

# Toolchain setup
export ARCH="arm64"
CROSS_COMPILE="$PWD/../Toolchains/aarch64-49/bin/aarch64-linux-android-"
CROSS_COMPILE_ARM32="$PWD/../Toolchains/arm-49/bin/arm-linux-androideabi-"

# Clang setup
CLANG_DIR="$PWD/../Toolchains/clang10"
CLANG_TRIPLE="aarch64-linux-gnu-"
CC="$CLANG_DIR/bin/clang"
KBUILD_COMPILER_STRING=$(${CC} --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

# Export
export CCACHE KBUILD_COMPILER_STRING CLANG_TRIPLE CORE CROSS_COMPILE CROSS_COMPILE_ARM32

start () {
        time make -j"${CORE}" \
            O=out \
            ARCH="${ARCH}" \
            CC="${CCACHE} ${CC}" \
            CLANG_TRIPLE="${CLANG_TRIPLE}" \
            CROSS_COMPILE="${CROSS_COMPILE}" \
            CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32}"
}

make O=out ARCH=arm64 $CONFIG
start