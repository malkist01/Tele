#!/usr/bin/env bash
rm -rf kernel
git clone $REPO -b $BRANCH kernel 
cd kernel
echo "Nuke previous toolchains"
rm -rf toolchain out AnyKernel
echo "cleaned up"
echo "Cloning toolchain"
git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 gcc-64
echo "Done"
if [ "$is_test" = true ]; then
     echo "Its alpha test build"
     unset chat_id
     unset token
     export chat_id=${my_id}
     export token=${nToken}
else
     echo "Its beta release build"
fi
SHA=$(echo $DRONE_COMMIT_SHA | cut -c 1-8)
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
DATE=$(date +'%H%M-%d%m%y')
START=$(date +"%s")
CODENAME=mido
DEF=teletubies_defconfig
export CROSS_COMPILE="$(pwd)/gcc-64/bin/aarch64-elf-"
export PATH="$(pwd)/gcc-64/bin:$PATH"
export ARCH=arm64
export KBUILD_BUILD_USER=malkist
export KBUILD_BUILD_HOST=android
# Push kernel to channel
function push() {
    cd AnyKernel || exit 1
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>Samsung J6+</b>"
}
# Compile plox
function compile() {
	make -j$(nproc --all) O=out 
     make -j $(nproc --all) O=out ${DEF}
     CONFIG_DEBUG_SECTION_MISMATCH=y 
	CONFIG_NO_ERROR_ON_MISMATCH=y   2>&1 | tee error.log     

     if ! [ -a "$IMAGE" ]; then
        finderr
        exit 1
     fi
    git clone --depth=1 https://github.com/malkist01/anykernel3.git AnyKernel -b master
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}
# Zipping
zipping() {
    cd AnyKernel || exit 1
    zip -r9 Teletubies-"${CODENAME}"-Arm64"${DATE}".zip ./*
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
