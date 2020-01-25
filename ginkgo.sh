#!/usr/bin/env bash

# Color
red="\033[1;31m"
yellow="\033[1;33m"
green="\033[1;32m"
echo -e "$yellow"

# environtment
KERNEL_DIR=$PWD
KERNEL_OUT=$pwd/out/arch/arm64/boot/Image.gz-dtb
CONFIG=$pwd/vendor/mystic-ginkgo_defconfig
CORE="$(grep -c '^processor' /proc/cpuinfo)"
CCACHE="$(command -v ccache)"

# Toolchain setup
export ARCH="arm64"
CROSS_COMPILE="$PWD/../Toolchains/aarch64-ubertc/bin/aarch64-linux-android-"
CROSS_COMPILE_ARM32="$PWD/../Toolchains/arm-ubertc/bin/arm-linux-androideabi-"

# Export
export CCACHE CORE CROSS_COMPILE CROSS_COMPILE_ARM32

start () {
        time make -j"${CORE}" \
            O=out \
            ARCH="${ARCH}" \
            CROSS_COMPILE="${CROSS_COMPILE}" \
            CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32}"
}

make O=out ARCH=arm64 $CONFIG
start