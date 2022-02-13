#!/usr/bin/env bash
# Copyright (C) 2020-2022 Oktapra Amtono <oktapra.amtono@gmail.com>
# Docker Kernel Build Script

# Clone kernel source
if [[ "$*" =~ "stable" ]]; then
    git clone --depth=1 https://github.com/okta-10/mystic_kernel_sdm660-4.19.git -b Mystic-4.19 kernel
    cd kernel || exit
elif [[ "$*" =~ "beta" ]]; then
    git clone --depth=1 https://"${GH_TOKEN}":x-oauth-basic@github.com/okta-10/mystic-beta.git -b Mystic-4.19 kernel
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
git clone --depth=1 https://github.com/okta-10/AnyKernel3.git -b a26x ak3-a26x
git clone --depth=1 https://github.com/okta-10/AnyKernel3.git -b lavender ak3-lavender
git clone --depth=1 https://github.com/okta-10/AnyKernel3.git -b whyred ak3-whyred

# Telegram setup
push_message() {
    curl -s -X POST \
        https://api.telegram.org/bot"{$TG_BOT_TOKEN}"/sendMessage \
        -d chat_id="${TG_CHAT_ID}" \
        -d text="$1" \
        -d "parse_mode=html" \
        -d "disable_web_page_preview=true"
}

# Push message to telegram
push_message "
<b>======================================</b>
<b>Start Building :</b> <code>Mystic Kernel</code>
<b>Linux Version :</b> <code>$(make kernelversion | cut -d " " -f5 | tr -d '\n')</code>
<b>Source Branch :</b> <code>$(git rev-parse --abbrev-ref HEAD)</code>
<b>======================================</b> "
