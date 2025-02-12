#!/bin/bash

# Make sure setup has been executed
if [ ! -d extern/install ]; then
    echo "Have you run ./setup.sh yet??"
    exit -1
fi

HOST_INITRAMFS="${PWD}/initramfs"
GUEST_INITRAMFS="${PWD}/guest-initramfs"

# Source the requested configuration file
source config.sh

if [ -z $KERNEL_SOURCE ]; then
    echo "Must set KERNEL_SOURCE variable in config.sh"
    exit 1
fi

RELEASE_FILE="include/config/kernel.release"

# Determine the kernel release by invoking the kernel makefile
get_kernel_release() {
    local headers=$1
    local release_file="$headers/$RELEASE_FILE"

    # If file does not exist, build it
    if [ ! -f $release_file ]; then
        make -C $headers $RELEASE_FILE &> build.log
        if [ $? -ne 0 ]; then
            echo "Failed to generate $headers/$RELEASE_FILE. See build.log" 1>&2
            return 
        fi

        rm -f build.log
    fi

    local release=$(cat $headers/$RELEASE_FILE)
    echo $release
}

KERNEL_RELEASE=$(get_kernel_release $KERNEL_SOURCE)
if [ -z $KERNEL_RELEASE ]; then
    echo "Failed to determine KERNEL_RELEASE from kernel headers"
    exit 1
fi

if [ $WANT_GUEST_ISOIMAGE -eq 1 ] && [ ! -z $GUEST_KERNEL_SOURCE ]; then
    GUEST_KERNEL_RELEASE=$(get_kernel_release $GUEST_KERNEL_SOURCE)
    if [ -z $GUEST_KERNEL_RELEASE ]; then
        echo "Failed to determine KERNEL_RELEASE from kernel headers"
        exit 1
    fi
fi

pushd build

export WANT_LEVIATHAN
export LEVIATHAN_SOURCE
export WANT_MODULES

if [ $WANT_GUEST_ISOIMAGE -eq 1 ]; then
    echo "Building guest iso image ..."

    # Install kernel and modules in guest
    GUEST=1 INITRAMFS=${GUEST_INITRAMFS} GUEST_KERNEL_RELEASE=${GUEST_KERNEL_RELEASE} \
        KERNEL_SOURCE=${GUEST_KERNEL_SOURCE} source ./install.sh 

    # Build guest iso
    # sed -i "s/console=[a-zA-Z0-9]*/console=${GUEST_CONSOLE}/g" guest.cfg 
    KERNEL_SOURCE=${GUEST_KERNEL_SOURCE} INITRD="${GUEST_INITRAMFS}.cpio.gz" CONFIG="guest.cfg" \
        source ./gen-isoimage.sh 

    # Copy guest iso to host initramfs
    mkdir -p ${HOST_INITRAMFS}/opt/isos
    mv image.iso ${HOST_INITRAMFS}/opt/isos/guest-img.iso
    rm "${GUEST_INITRAMFS}.cpio.gz"
else
    rm -f ${HOST_INITRAMFS}/opt/isos/guest-img.iso
fi

# Install kernel and modules in host
GUEST=0 INITRAMFS=${HOST_INITRAMFS} KERNEL_RELEASE=${KERNEL_RELEASE} KERNEL_SOURCE=${KERNEL_SOURCE} \
    source ./install.sh

rm -f ../images/image.iso
rm -f ../images/initrd.img
rm -f ../images/bzImage

INITRD="${HOST_INITRAMFS}.cpio.gz"
KERNEL="${KERNEL_SOURCE}/arch/x86/boot/bzImage"

# Install in PXE dir, if wanted
if [ $WANT_PXEBOOT -eq 1 ]; then
    echo "installing to ${PXEBOOT_DIR}"
    cp $INITRD "${PXEBOOT_DIR}/initrd"
    cp $KERNEL "${PXEBOOT_DIR}/bzImage"
fi

# Build host iso, or save initrd/bzimage
if [ $WANT_ISOIMAGE -eq 1 ]; then
    KERNEL_SOURCE=${KERNEL_SOURCE} INITRD=${INITRD} CONFIG="host.cfg" \
        source ./gen-isoimage.sh 

    mkdir -p ../images
    mv image.iso ../images/image.iso
    rm $INITRD
else
    mv $INITRD ../images/initrd
    cp $KERNEL ../images/bzImage
fi

popd
