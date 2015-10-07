#!/bin/bash

# Sanity check
if [[ "$#" -lt 2 ]]; 
then
    echo "Illegal number of parameters"
    echo "usage: HOST_OUT_DIR TARGET_OUT_DIR"
    exit
fi

# Remove old output
rm -rf out/
rm usr/src/linux-4.0.5-gentoo/.config

#General Directives
NUM_THREADS=16

if [[ -z "$TARGET_OUT_DIR" ]]
then
   export TARGET_OUT_DIR=$2
fi

if [[ -z "$HOST_OUT_DIR" ]]
then
   export HOST_OUT_DIR=$1
fi

# Portage Tree
mkdir -p $TARGET_OUT_DIR/usr/portage
# Portage Cache
mkdir -p $TARGET_OUT_DIR/var/cache/edb
# Temporary Portage Files
mkdir -p $TARGET_OUT_DIR/var/tmp/portage
mkdir -p $TARGET_OUT_DIR/var/tmp/genkernel
# Kernel Source & Build
mkdir -p $TARGET_OUT_DIR/usr/src

# Portage Tree
mount --rbind $HOST_OUT_DIR/usr/portage $TARGET_OUT_DIR/usr/portage
mount --make-rslave $TARGET_OUT_DIR/usr/portage

# Portage Cache
mount --rbind $HOST_OUT_DIR/var/cache/edb $TARGET_OUT_DIR/var/cache/edb
mount --make-rslave $TARGET_OUT_DIR/var/cache/edb

# Temporary Portage Files
# (and build folders)
mount --rbind $HOST_OUT_DIR/var/tmp/portage $TARGET_OUT_DIR/var/tmp/portage
mount --make-rslave $TARGET_OUT_DIR/var/tmp/portage
mount --rbind $HOST_OUT_DIR/var/tmp/genkernel $TARGET_OUT_DIR/var/tmp/genkernel
mount --make-rslave $TARGET_OUT_DIR/var/tmp/genkernel

# Kernel Source & Build
mount --rbind $HOST_OUT_DIR/usr/src $TARGET_OUT_DIR/usr/src
mount --make-rslave $TARGET_OUT_DIR/usr/src
mkdir -p out/$KERNEL_VERSION
cp -p usr/src/linux-4.0.5-gentoo/arch/x86/configs/pegatron_defconfig usr/src/linux-4.0.5-gentoo/.config
cd usr/src/linux-4.0.5-gentoo/
make clean ARCH=x86_64
export KERNEL_VERSION=$(make -s kernelrelease ARCH=x86)
SCRIPT_INSTALL_MOD_BASE=$PWD/out/$KERNEL_VERSION
SCRIPT_INSTALL_PATH=$PWD/out/$KERNEL_VERSION
make -j$NUM_THREADS ARCH=x86_64
make -j$NUM_THREADS ARCH=x86_64 INSTALL_MOD_PATH=$SCRIPT_INSTALL_MOD_PATH modules_install
make -j$NUM_THREADS ARCH=x86_64 INSTALL_PATH=$SCRIPT_INSTALL_PATH install

# Create swap file
dd if=/dev/zero of=$TARGET_OUT_DIR/swapfile bs=1M count=2048
mkswap $TARGET_OUT_DIR/swapfile
swapon -v $TARGET_OUT_DIR/swapfile

swapoff -a
rm -v $TARGET_OUT_DIR/swapfile
