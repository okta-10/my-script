#!/usr/bin/env bash
# Copyright (C) 2020-2021 Oktapra Amtono
# Docker Kernel Build Script

# Kernel Directory
KERNEL_DIR=$PWD

# Device Name
if [[ "$*" =~ "whyred" ]]; then
	DEVICE="whyred"
elif [[ "$*" =~ "lavender" ]]; then
	DEVICE="lavender"
elif [[ "$*" =~ "a26x" ]]; then
	DEVICE="a26x"
fi

if [[ "$*" =~ "oc" ]]; then
	export LOCALVERSION="-OC"
fi

# Setup Environtment
export TZ="Asia/Jakarta"
ZIP_DATE=$(TZ=Asia/Jakarta date +'%d%m%Y')
KERNEL_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
SOURCE="$(git rev-parse --abbrev-ref HEAD)"
AK3_DIR=$KERNEL_DIR/ak3-$DEVICE/

if [[ "$*" =~ "clang" ]]; then
	# Clang Setup
	CLANG_DIR="$KERNEL_DIR/clang"
	export PATH="$KERNEL_DIR/clang/bin:$PATH"
	KBUILD_COMPILER_STRING="$("$CLANG_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
	export KBUILD_COMPILER_STRING
fi

export ZIP_DATE
export SOURCE
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="okta_10"
export KBUILD_BUILD_HOST="dockerci"

# Telegram
TELEGRAM=Telegram/telegram
sendInfo() {
	"${TELEGRAM}" -c "${CHANNEL_ID}" -H -D \
		"$(
			for POST in "${@}"; do
				echo "${POST}"
			done
		)"
}

sendKernel() {
	"${TELEGRAM}" -f "$(echo "$AK3_DIR"/*.zip)" \
		-c "${CHANNEL_ID}" -H \
		"# <code>$DEVICE</code> # <code>md5: $(md5sum "$AK3_DIR"/*.zip | cut -d' ' -f1)</code> # <code>Build Took : $(("$DIFF" / 60)) Minute, $(("$DIFF" % 60)) Second</code>"
}

# Start Count
BUILD_START=$(date +"%s")

# Export Defconfig
make O=out vendor/mystic-"$DEVICE"_defconfig

# Start Compile
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

# If build error
if ! [ -a "$KERNEL_IMG" ]; then
	sendInfo "<b>Failed building kernel for <code>$DEVICE</code> Please fix it...!</b>"
	exit 1
fi

# End Count and Calculate Total Build Time
BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))

# Make zip
cp -r "$KERNEL_IMG" "$AK3_DIR"/
cd "$AK3_DIR" || exit
if [[ "$*" =~ "oc" ]]; then
	zip -r9 Mystic-"$DEVICE"_beta"$LOCALVERSION"_"$ZIP_DATE".zip ./*
else
	zip -r9 Mystic-"$DEVICE"_beta_"$ZIP_DATE".zip ./*
fi
cd "$KERNEL_DIR" || exit

sendKernel

rm -rf out/arch/arm64/boot/
rm -rf out/.version
rm -rf "$AK3_DIR"/*.zip
