#!/usr/bin/env bash
# Copyright (C) 2020-2022 Oktapra Amtono <oktapra.amtono@gmail.com>
# Docker Kernel Build Script

# Start counting
BUILD_START=$(date +"%s")

# Name and version of kernel
DEVICE="surya"
KERNEL_NAME="Mystic"
KERNEL_VERSION="_beta"

# Clone kernel source
if [[ "$*" =~ "beta" ]]; then
    git clone --depth=1 https://"${GH_TOKEN}":x-oauth-basic@github.com/okta-10/mystic-beta.git -b Mystic-4.14 kernel
    cd kernel || exit
elif [[ "$*" =~ "stable" ]]; then
    git clone --depth=1 https://github.com/okta-10/mystic_kernel_sdm732-4.14.git -b Mystic-4.14 kernel
    cd kernel || exit
fi

# Clone toolchain
if [[ "$*" =~ "clang" ]]; then
    git clone --depth=1 https://gitlab.com/okta-10/mystic-clang.git clang
elif [[ "$*" =~ "gcc" ]]; then
    git clone --depth=1 https://github.com/okta-10/gcc-arm32.git arm32
    git clone --depth=1 https://github.com/okta-10/gcc-arm64.git arm64
fi

# Clone anykernel3
git clone --depth=1 https://github.com/okta-10/AnyKernel3.git -b surya ak3-surya

# Setup environtment
KERNEL_DIR=$PWD
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="okta_10"
export KBUILD_BUILD_HOST="ArchLinux"
AK3_DIR=$KERNEL_DIR/ak3-$DEVICE
KERNEL_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
KERNEL_DTBO=$KERNEL_DIR/out/arch/arm64/boot/dtbo.img
ZIP_DATE=$(TZ=Asia/Jakarta date +'%Y%m%d-%H%M')
ZIP_NAME="$KERNEL_NAME"_"$DEVICE""$KERNEL_VERSION"_"$ZIP_DATE".zip
CORES=$(grep -c ^processor /proc/cpuinfo)
CPU=$(lscpu | sed -nr '/Model name/ s/.*:\s*(.*) */\1/p')

# Setup toolchain
if [[ "$*" =~ "clang" ]]; then
    CLANG_DIR="$KERNEL_DIR/clang"
    export PATH="$KERNEL_DIR/clang/bin:$PATH"
    CLGV="$("$CLANG_DIR"/bin/clang --version | head -n 1)"
    BINV="$("$CLANG_DIR"/bin/ld --version | head -n 1)"
    LLDV="$("$CLANG_DIR"/bin/ld.lld --version | head -n 1)"
    export KBUILD_COMPILER_STRING="$CLGV - $BINV - $LLDV"
elif [[ "$*" =~ "gcc" ]]; then
    GCC_DIR="$KERNEL_DIR/arm64"
    GCCV="$("$GCC_DIR"/bin/aarch64-elf-gcc --version | head -n 1)"
    BINV="$("$GCC_DIR"/bin/aarch64-elf-ld --version | head -n 1)"
    LLDV="$("$GCC_DIR"/bin/aarch64-elf-ld.lld --version | head -n 1)"
    export KBUILD_COMPILER_STRING="$GCCV - $BINV - $LLDV"
fi

# Telegram setup
push_message() {
    curl -s -X POST \
        https://api.telegram.org/bot"{$TG_BOT_TOKEN}"/sendMessage \
        -d chat_id="${TG_CHAT_ID}" \
        -d text="$1" \
        -d "parse_mode=html" \
        -d "disable_web_page_preview=true"
}

push_document() {
    curl -s -X POST \
        https://api.telegram.org/bot"{$TG_BOT_TOKEN}"/sendDocument \
        -F chat_id="${TG_CHAT_ID}" \
        -F document=@"$1" \
        -F caption="$2" \
        -F "parse_mode=html" \
        -F "disable_web_page_preview=true"
}

# Push info while start building
push_message "
<b>======================================</b>
<b>Start Building :</b> <code>Mystic Kernel</code>
<b>Linux Version :</b> <code>$(make kernelversion | cut -d " " -f5 | tr -d '\n')</code>
<b>Source Branch :</b> <code>$(git rev-parse --abbrev-ref HEAD)</code>
<b>======================================</b> "

# Export defconfig
make O=out vendor/mystic-"$DEVICE"_defconfig

# Start compile
if [[ "$*" =~ "clang" ]]; then
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

# Push message if build error
if ! [ -a "$KERNEL_IMG" ]; then
    push_message "<b>Failed building kernel for <code>$DEVICE</code> Please fix it...!</b>"
    exit 1
fi

# Make zip
cp -r "$KERNEL_IMG" "$AK3_DIR"/
cp -r "$KERNEL_DTBO" "$AK3_DIR"/
cd "$AK3_DIR" || exit
zip -r9 "$ZIP_NAME" ./*
cd "$KERNEL_DIR" || exit

# End count and calculate total build time
BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))

# Push kernel to telegram
push_document "$AK3_DIR/$ZIP_NAME" "
<b>device :</b> <code>$DEVICE</code>
<b>md5 :</b> <code>$(md5sum "$AK3_DIR/$ZIP_NAME" | cut -d' ' -f1)</code>
<b>build took :</b> <code>$(("$DIFF" / 60)) minute, $(("$DIFF" % 60)) second</code>"

# Push message to telegram
push_message "
<b>======================================</b>
<b>Success Building :</b> <code>Mystic Kernel</code>
<b>Linux Version :</b> <code>$(make kernelversion | cut -d " " -f5 | tr -d '\n')</code>
<b>Build Date :</b> <code>$(date +"%A, %d %b %Y, %H:%M:%S")</code>
<b>Build Using :</b> <code>$CPU $CORES thread</code>
<b>Toolchain :</b> <code>$KBUILD_COMPILER_STRING</code>
<b>Last Changelog :</b> <code>$(git log --pretty=format:'%s' -1)</code>
<b>======================================</b>
<b>Provide your feedback in the @MysticKernelDiscussion group for this Beta Build 😉</b> "
