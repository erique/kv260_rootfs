#!/bin/bash

set -e

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $REPO_ROOT

KV260=${REPO_ROOT}/kv260

mkdir -p ${KV260}/overlay/usr/lib
cat > ${KV260}/overlay/usr/lib/os-release <<EOF 
NAME="FPGAArcade Replay for KV260"
VERSION=`date +%Y.%m.%d`
ID=replay
VERSION_ID=`git describe --tag --always --dirty`
BUILD_ID=`date +%Y.%m.%d`-g`git describe --tag --always --dirty`
PRETTY_NAME="FPGAArcade Replay for KV260 `date +%Y.%m.%d`"
HOME_URL=`git config --get remote.origin.url | sed 's/git@github.com:/https:\/\/github.com\//'`
EOF

rm -rf ${REPO_ROOT}/out
make -C buildroot O=$PWD/out defconfig BR2_DEFCONFIG=$PWD/zynqmp_kv260_defconfig

# pre-build cache size
du -sch ${HOME}/.buildroot-cache/* || true
make -C out ccache-stats

# get stats
make -C out

# get stats
make -C out graph-build graph-size 

# post-build cache size
du -sch ${HOME}/.buildroot-cache/*
make -C out ccache-stats

# copy out results
cp out/build/arm-trusted-firmware-xlnx_rebase_v2.4_2021.1_update1/build/zynqmp/debug/bl31/bl31.elf .
cp out/images/u-boot     u-boot.elf
cp out/images/u-boot.dtb u-boot.dtb

# create boot.bin
./out/build/uboot-xilinx-v2021.2/tools/mkimage -T zynqmpbif -d bootgen.bif boot.bin
