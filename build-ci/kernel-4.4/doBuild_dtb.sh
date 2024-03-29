#!/usr/bin/env bash
# Copyright (C) 2020-2022 Oktapra Amtono <oktapra.amtono@gmail.com>
# Docker Kernel Build Script

# Kernel directory
KERNEL_DIR=$PWD

# Device name
if [[ "$*" =~ "a26x" ]]; then
    DEVICE="a26x"
elif [[ "$*" =~ "lavender" ]]; then
    DEVICE="lavender"
elif [[ "$*" =~ "tulip" ]]; then
    DEVICE="tulip"
elif [[ "$*" =~ "whyred" ]]; then
    DEVICE="whyred"
fi

# Setup environtment
export ARCH=arm64
export SUBARCH=arm64
AK3_DIR=$KERNEL_DIR/ak3-$DEVICE

# Export defconfig
make O=out mystic-"$DEVICE"-oldcam_defconfig

# Start compile
if [[ "$*" =~ "clang" ]]; then
    export PATH="$KERNEL_DIR/clang/bin:$PATH"
    make -j"$(nproc --all)" O=out \
        CC=clang \
        AR=llvm-ar \
        NM=llvm-nm \
        OBJCOPY=llvm-objcopy \
        OBJDUMP=llvm-objdump \
        STRIP=llvm-strip \
        CROSS_COMPILE=aarch64-linux-gnu- \
        CROSS_COMPILE_ARM32=arm-linux-gnueabi-
elif [[ "$*" =~ "gcc" ]]; then
    export CROSS_COMPILE="$KERNEL_DIR/arm64/bin/aarch64-elf-"
    export CROSS_COMPILE_ARM32="$KERNEL_DIR/arm32/bin/arm-eabi-"
    make -j"$(nproc --all)" O=out ARCH=arm64
fi

# Copy dtbs
if [[ "$*" =~ "qpnp" ]]; then
    cp -r out/arch/arm64/boot/dts/qcom/sdm636-*.dtb "$AK3_DIR"/dtbs/qpnp/
    cp -r out/arch/arm64/boot/dts/qcom/sdm660-*.dtb "$AK3_DIR"/dtbs/qpnp/
elif [[ "$*" =~ "qti" ]]; then
    cp -r out/arch/arm64/boot/dts/qcom/sdm636-*.dtb "$AK3_DIR"/dtbs/qti/
    cp -r out/arch/arm64/boot/dts/qcom/sdm660-*.dtb "$AK3_DIR"/dtbs/qti/
fi

rm -rf out/arch/arm64/boot/
rm -rf out/.version
