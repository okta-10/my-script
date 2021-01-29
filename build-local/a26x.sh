#!/usr/bin/env bash
# Copyright (C) 2020-2021 Oktapra Amtono
# Build Script

# Color
red="\033[1;31m"
echo -e "$red"

# environtment
KERNEL_DIR=$PWD
KERNEL_OUT=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
AK3_DIR=$KERNEL_DIR/../AK3/AK3-a26x
CODENAME="A26X" #Jasmine/Wayne
CONFIG_OLD=mystic-a26x-oldcam_defconfig
CONFIG_NEW=mystic-a26x-newcam_defconfig
CONFIG_TEN=mystic-a26x-tencam_defconfig
CORE="$(grep -c '^processor' /proc/cpuinfo)"

# Setup Clang
export PATH="/home/okta_10/Android-Stuff/Toolchain/proton-clang/bin:$PATH"
CLANG_DIR="/home/okta_10/Android-Stuff/Toolchain/proton-clang"
KBUILD_COMPILER_STRING="$(${CLANG_DIR}/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"

# Export
export TZ="Asia/Jakarta"
ZIP_DATE=$(TZ=Asia/Jakarta date +'%d%m%Y')
export ZIP_DATE
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_COMPILER_STRING

while true; do
    # Menu
    echo -e ""
    echo -e " Menu                                                               "
    echo -e " ╔═════════════════════════════════════════════════════════════════╗"
    echo -e " ║ 1. Export A26X OldCam defconfig to Out Dir                      ║"
    echo -e " ║ 2. Export A26X NewCam defconfig to Out Dir                      ║"
    echo -e " ║ 3. Export A26X TenCam defconfig to Out Dir                      ║"
    echo -e " ║ 4. Start Compile With Clang                                     ║"
    echo -e " ║ 5. Copy Image.gz-dtb to Flashable Dir                           ║"
    echo -e " ║ 6. Make Zip                                                     ║"
    echo -e " ║ e. Back Main Menu                                               ║"
    echo -e " ╚═════════════════════════════════════════════════════════════════╝"
    echo -ne "\n Enter your choice 1-4, or press 'e' for back to Main Menu : "

    read -r menu

    # Export oldcam deconfig
    if [[ "$menu" == "1" ]]; then
        make O=out $CONFIG_OLD
        echo -e "\n (i) Success export $CONFIG_OLD defonfig to Out Dir"
        echo -e ""
    fi

    # Export newcam deconfig
    if [[ "$menu" == "2" ]]; then
        make O=out $CONFIG_NEW
        echo -e "\n (i) Success export $CONFIG_NEW defonfig to Out Dir"
        echo -e ""
    fi

    # Export tencam deconfig
    if [[ "$menu" == "3" ]]; then
        make O=out $CONFIG_TEN
        echo -e "\n (i) Success export $CONFIG_TEN defonfig to Out Dir"
        echo -e ""
    fi

    # Build With Clang
    if [[ "$menu" == "4" ]]; then
        echo -e ""
        START=$(date +"%s")
        CURRENTDATE=$(date +"%A, %d %b %Y, %H:%M:%S")
        echo -e "\n (i) Start Compile kernel for $CODENAME, started at $CURRENTDATE using $CORE thread"
        echo -e "\n"

        # Run Build
        make -j"$CORE" O=out CC=clang AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-

        if ! [ -a "$KERNEL_OUT" ]; then
            echo -e "\n (!) Compile Kernel for $CODENAME failed, See buildlog to fix errors"
        fi

        END=$(date +"%s")
        TOTAL_TIME=$(("$END" - "$START"))
        echo -e "\n (i) Compile Kernel for $CODENAME successfully, Kernel Image in $KERNEL_OUT"
        echo -e " (i) Total time elapsed: $(("$TOTAL_TIME" / 60)) Minutes, $(("$TOTAL_TIME" % 60)) Second."
        echo -e "\n"
    fi

    # Move kernel to flashable dir
    if [[ "$menu" == "5" ]]; then
        cp "$KERNEL_OUT" "$AK3_DIR"/Image.gz-dtb

        echo -e "\n (i) Done moving kernel img to $AK3_DIR"
    fi

    # Make Zip
    if [[ "$menu" == "6" ]]; then
        cd "$AK3_DIR" || exit
        zip -r9 Mystic-"$CODENAME"-EAS_"$ZIP_DATE".zip ./*
        cd "$KERNEL_DIR" || exit

        echo -e "\n (i) Done Zipping Kernel"
    fi

    # Exit
    if [[ "$menu" == "e" ]]; then
        exit
    fi

done
