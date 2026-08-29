#!/bin/bash
set -euo pipefail
cd "$GITHUB_WORKSPACE"

git clone --depth 1 -b android-10.0 https://github.com/yogurt-devs/android_kernel_micromax_yogurt.git kernel
cd kernel
git apply ../cmd27.patch
grep -n "MMC_PROGRAM_CSD" drivers/mmc/host/mediatek/ComboA/sd.c
sudo ln -sf /usr/bin/python3 /usr/bin/python
find tools/dct -name '*.py' | xargs python3 -m lib2to3 -w -n || true
sed -i '1s|.*|#!/usr/bin/env python3|' tools/dct/DrvGen.py
grep -rn 'def cmp(a, b):' tools/dct/DrvGen.py > /dev/null || sed -i 's/^import getopt/import getopt\n\ndef cmp(a, b):\n    return (a > b) - (a < b)/' tools/dct/DrvGen.py
cd ..


git clone --depth=1 https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-5484270 clang
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 los-4.9-64
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 los-4.9-32

mkdir -p kernel/out
cd kernel
make O=out ARCH=arm64 E7746_defconfig
PATH="${GITHUB_WORKSPACE}/clang/bin:${GITHUB_WORKSPACE}/los-4.9-32/bin:${GITHUB_WORKSPACE}/los-4.9-64/bin:${PATH}" \
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC='clang -Qunused-arguments -fcolor-diagnostics' \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE="${GITHUB_WORKSPACE}/los-4.9-64/bin/aarch64-linux-android-" \
                      CROSS_COMPILE_ARM32="${GITHUB_WORKSPACE}/los-4.9-32/bin/arm-linux-androideabi-" \
                      CONFIG_NO_ERROR_ON_MISMATCH=y \
                      Image.gz-dtb
cp out/arch/arm64/boot/Image.gz-dtb "$GITHUB_WORKSPACE/Image.gz-dtb"
ls -la "$GITHUB_WORKSPACE/Image.gz-dtb"
