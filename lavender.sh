#!/usr/bin/env bash

# Color
red="\033[1;31m"
yellow="\033[1;33m"
green="\033[1;32m"
echo -e "$red"

# environtment
KERNEL_DIR=$PWD
KERNEL_OUT=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
AK3_DIR=$KERNEL_DIR/../AnyKernel3
CONFIG_OLDCAM=mystic-lavender_defconfig
CONFIG_NEWCAM=mystic-lavender-newcam_defconfig
CORE="$(grep -c '^processor' /proc/cpuinfo)"

# Setup GCC Toolchain
CROSS_COMPILE="$PWD/../Toolchain/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
CROSS_COMPILE_ARM32="$PWD/../Toolchain/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"

# Export
export TZ=":Asia/Jakarta"
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE
export CROSS_COMPILE_ARM32

while true; do
    # Menu
	echo -e ""
    echo -e " Menu                                                               "
    echo -e " ╔═════════════════════════════════════════════════════════════════╗"
    echo -e " ║ 1. Export Lavender Old Cam defconfig to Out Dir                 ║"
    echo -e " ║ 2. Export Lavender New Cam defconfig to Out Dir                 ║"
    echo -e " ║ 3. Start Compile GCC Only                                       ║"
    echo -e " ║ 4. Start Compile With Clang                                     ║"
    echo -e " ║ 5. Copy Image.gz-dtb to Flashable Dir                           ║"
    echo -e " ║ e. Back Main Menu                                               ║"
    echo -e " ╚═════════════════════════════════════════════════════════════════╝"
    echo -ne "\n Enter your choice 1-4, or press 'e' for back to Main Menu : "

    read menu

    # Export old cam deconfig
    if [[ "$menu" == "1" ]]; then
        make O=out $CONFIG_OLDCAM
        echo -e "\n (i) Success export $CONFIG_OLDCAM defonfig to Out Dir"
        echo -e ""
    fi

    # Export new cam deconfig
    if [[ "$menu" == "2" ]]; then
        make O=out $CONFIG_NEWCAM
        echo -e "\n (i) Success export $CONFIG_NEWCAM defonfig to Out Dir"
        echo -e ""
    fi

    # build GCC only
    if [[ "$menu" == "3" ]]; then
        start () {
                time make -j"${CORE}" \
                O=out \
                ARCH="${ARCH}" \
                CROSS_COMPILE="${CROSS_COMPILE}" \
                CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32}"
            }

        START=$(date +"%s")
        CURRENTDATE=`date +"%A, %d %b %Y, %H:%M:%S"`
        echo -e "\n (i) Compile kernel started at $CURRENTDATE using $CORE thread"
        echo -e "\n"
        make O=out
        END=$(date +"%s")
        TOTAL_TIME=$(($END - $START))
        echo -e "\n (i) Compile successfully, Kernel Image in $KERNEL_OUT"
        echo -e " (i) Total time elapsed: $(($TOTAL_TIME / 60)) Minutes, $(($TOTAL_TIME % 60)) Second."
        echo -e "\n"
     fi

    # Build With Clang
    if [[ "$menu" == "4" ]]; then

        # Setup Clang
        CLANG_DIR="$PWD/../Toolchain/clang-r377782c"
        export CLANG_TRIPLE="aarch64-linux-gnu-"
        export CC="$CLANG_DIR/bin/clang"
        export KBUILD_COMPILER_STRING=$(${CC} --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

        start () {
                time make -j"${CORE}" \
                O=out \
                ARCH="${ARCH}" \
                CC="${CC}" \
                CLANG_TRIPLE="${CLANG_TRIPLE}" \
                CROSS_COMPILE="${CROSS_COMPILE}" \
                CROSS_COMPILE_ARM32="${CROSS_COMPILE_ARM32}"
            }

        START=$(date +"%s")
        CURRENTDATE=`date +"%A, %d %b %Y, %H:%M:%S"`
        echo -e "\n (i) Compile kernel started at $CURRENTDATE using $CORE thread"
        echo -e "\n"
        make O=out
        END=$(date +"%s")
        TOTAL_TIME=$(($END - $START))
        echo -e "\n (i) Compile successfully, Kernel Image in $KERNEL_OUT"
        echo -e " (i) Total time elapsed: $(($TOTAL_TIME / 60)) Minutes, $(($TOTAL_TIME % 60)) Second."
        echo -e "\n"
    fi

    # Move kernel to flashable dir
    if [[ "$menu" == "5" ]]; then
        cd $AK3_DIR
        cp $KERNEL_OUT $AK3_DIR/Image.gz-dtb

        echo -e "\n (i) Done moving kernel to $AK3_DIR"
    fi

    # Exit
    if [[ "$menu" == "e" ]]; then
    	exit
    fi

done
