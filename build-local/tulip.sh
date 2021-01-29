#!/usr/bin/env bash
# Copyright (C) 2020-2021 Oktapra Amtono
# Build Script

# Color
blue="\033[1;36m"
echo -e "$blue"

# environtment
KERNEL_DIR=$PWD
KERNEL_OUT=$KERNEL_DIR/out/arch/arm64/boot/Image.gz
KERN_DTB=$KERNEL_DIR/out/arch/arm64/boot/dts/qcom/sdm636-mtp_e7t.dtb
AK3_DIR=$KERNEL_DIR/../AK3/AK3-tulip
CODENAME="Tulip"
CONFIG_OLD=mystic-tulip-oldcam_defconfig
CONFIG_NEW=mystic-tulip-newcam_defconfig
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
    echo -e " ║ 1. Export Tulip OldCam defconfig to Out Dir                     ║"
    echo -e " ║ 2. Export Tulip NewCam defconfig to Out Dir                     ║"
    echo -e " ║ 3. Start Compile With Clang                                     ║"
    echo -e " ║ 4. Copy Image.gz to Flashable Dir                               ║"
    echo -e " ║ 5. Copy dtb-uc to Flashable Dir                                 ║"
    echo -e " ║ 6. Copy dtb-oc to Flashable Dir                                 ║"
    echo -e " ║ 7. Make Zip                                                     ║"
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

    # Build With Clang
    if [[ "$menu" == "3" ]]; then
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
    if [[ "$menu" == "4" ]]; then
        cp "$KERNEL_OUT" "$AK3_DIR"/kernel/Image.gz

        echo -e "\n (i) Done moving kernel img to $AK3_DIR"
    fi

    # Copy dtb uc to flashable dir
    if [ "$menu" == "5" ]; then
        cd "$AK3_DIR" || exit
        cp "$KERN_DTB" "$AK3_DIR"/dtbs/mystic.dtb-uc
        cd "$KERNEL_DIR" || exit

        echo -e "\n(i) Done moving dtb-uc to $AK3_DIR."
    fi

    # Copy dtb oc to flashable dir
    if [ "$menu" == "6" ]; then
        cd "$AK3_DIR" || exit
        cp "$KERN_DTB" "$AK3_DIR"/dtbs/mystic.dtb-oc
        cd "$KERNEL_DIR" || exit

        echo -e "\n(i) Done moving dtb-oc to $AK3_DIR."
    fi

    # Make Zip
    if [[ "$menu" == "7" ]]; then
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
