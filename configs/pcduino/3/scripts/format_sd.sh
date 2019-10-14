#!/bin/bash

set -e

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if ! parted -h > /dev/null; then
  echo "Please install 'parted' and try again."
  exit 1
fi

if ! command -v mkfs.vfat > /dev/null 2>&1; then
  echo "Please install 'mkfs.vfat' (usually dosfstools) and try again."
  exit 1
fi

if [ -z "$PCDUINO_SD" ]; then
  echo "Please set PCDUINO_SD and try again."
  exit 1
fi

if [ ! -b "$PCDUINO_SD" ]; then
  echo "$PCDUINO_SD is not a block device or doesn't exist."
  exit 1
fi

ubootimg=$BUILDROOT_DIR/output/images/u-boot-sunxi-with-spl.bin
if [ ! -f "$ubootimg" ]; then
  echo "can't find u-boot image at $ubootimg"
  exit 1
fi

if [ -z "$SKIFF_NO_INTERACTIVE" ]; then
  read -p "Verify that '$PCDUINO_SD' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

MKEXT4="mkfs.ext4 -F -O ^64bit,^metadata_csum,resize_inode,sparse_super"

echo "Formatting device..."
parted "$PCDUINO_SD" mklabel msdos

echo "Making boot partition..."
parted -a optimal "$PCDUINO_SD" mkpart primary fat32 100MiB 410MiB

PCDUINO_SD_SFX=$PCDUINO_SD
if [ -b "${PCDUINO_SD}p1" ]; then
  PCDUINO_SD_SFX=${PCDUINO_SD}p
fi

echo "Making rootfs partition..."
parted -a optimal "$PCDUINO_SD" mkpart primary ext4 410MiB 600MiB

echo "Making persist partition..."
parted -a optimal "$PCDUINO_SD" -- mkpart primary ext4 600MiB -1s

sleep 1

echo "Building fat filesystem for boot..."
mkfs.vfat -F 32 "${PCDUINO_SD_SFX}1"
fatlabel "${PCDUINO_SD_SFX}1" boot

echo "Building ext4 filesystem for rootfs..."
$MKEXT4 -L rootfs "${PCDUINO_SD_SFX}2"

echo "Building ext4 filesystem for persist..."
$MKEXT4 -L persist "${PCDUINO_SD_SFX}3"

echo "Flashing u-boot..."
dd if="$ubootimg" of="$PCDUINO_SD" conv=fsync bs=1024 seek=8

echo Done!
