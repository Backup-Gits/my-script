#!/bin/bash
#
# Compile script for QuicksilveR kernel
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0 # builtin bash timer
ZIPNAME="Velvet-Miatoll-$(date '+%Y%m%d-%H%M').zip"
TC_DIR="$HOME/tc/proton-clang"
DEFCONFIG="cust_defconfig"

export KBUILD_BUILD_USER=TxExcalibur
export KBUILD_BUILD_HOST=VelvetHUB
export PATH="$TC_DIR/bin:$PATH"

if ! [ -d "$TC_DIR" ]; then
	echo "Proton clang not found! Cloning to $TC_DIR..."
	if ! git clone -q --depth=1 --single-branch https://github.com/kdrag0n/proton-clang "$TC_DIR"; then
		echo "Cloning failed! Aborting..."
		exit 1
	fi
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
	rm -rf out
fi

if [[ $1 = "-r" || $1 = "--regen" ]]; then
	make O=out ARCH=arm64 $DEFCONFIG savedefconfig
	cp out/defconfig arch/arm64/configs/$DEFCONFIG
	exit 1
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j"$(nproc --all)" O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz dtbo.img

if [ -f "out/arch/arm64/boot/Image.gz" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
	echo -e "\nKernel compiled succesfully! Zipping up...\n"
	if ! git clone -q https://github.com/Excalibur-99/AnyKernel3 -b master; then
		echo -e "\nCloning AnyKernel3 repo failed! Aborting..."
		exit 1
	fi
	cp out/arch/arm64/boot/Image.gz AnyKernel3
	cp out/arch/arm64/boot/dtbo.img AnyKernel3
	rm -f ./*zip
	cd AnyKernel3 || exit
	rm -rf out/arch/arm64/boot
	zip -r9 "../$ZIPNAME" ./* -x '*.git*' README.md ./*placeholder
	cd ..
	rm -rf AnyKernel3
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
	echo "Zip: $ZIPNAME"
	curl --upload-file "$ZIPNAME" https://free.keep.sh
	echo
else
	echo -e "\nCompilation failed!"
fi
