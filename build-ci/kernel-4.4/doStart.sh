#!/usr/bin/env bash
# Copyright (C) 2020-2022 Oktapra Amtono <oktapra.amtono@gmail.com>
# Docker Kernel Build Script

# Cloning some resource
if [[ "$*" =~ "stable" ]]; then
    git clone --depth=1 https://github.com/okta-10/mystic_kernel_sdm660-4.4.git -b Mystic-4.4 kernel
    cd kernel || exit
elif [[ "$*" =~ "beta" ]]; then
    git clone --depth=1 https://"${TOKED}":x-oauth-basic@github.com/okta-10/mystic-beta.git -b Mystic-4.4 kernel
    cd kernel || exit
fi

if [[ "$*" =~ "clang" ]]; then
    git clone --depth=1 https://github.com/okta-10/mystic-clang.git -b mystic clang
elif [[ "$*" =~ "gcc" ]]; then
    git clone --depth=1 https://github.com/okta-10/gcc-arm32.git arm32
    git clone --depth=1 https://github.com/okta-10/gcc-arm64.git arm64
fi

git clone --depth=1 https://github.com/okta-10/telegram.sh.git Telegram
git clone --depth=1 https://github.com/okta-10/AnyKernel3.git -b whyred-nondtb ak3-whyred
git clone --depth=1 https://github.com/okta-10/AnyKernel3.git -b tulip-nondtb ak3-tulip
git clone --depth=1 https://github.com/okta-10/AnyKernel3.git -b lavender ak3-lavender
git clone --depth=1 https://github.com/okta-10/AnyKernel3.git -b a26x ak3-a26x

# Telegram
TELEGRAM=Telegram/telegram
sendInfo() {
    "${TELEGRAM}" -c "${CHANNEL_ID}" -H \
        "$(
            for POST in "${@}"; do
                echo "${POST}"
            done
        )"
}

sendInfo "<b>======================================</b>" \
    "<b>Start Building :</b> <code>Mystic Kernel</code>" \
    "<b>Source Branch :</b> <code>$(git rev-parse --abbrev-ref HEAD)</code>" \
    "<b>======================================</b>"
