#!/bin/bash
set -e

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if ! sudo parted -h > /dev/null; then
  echo "Please install 'parted' and try again."
  exit 1
fi

if ! command -v mkfs.vfat >/dev/null 2>&1; then
  echo "Please install 'mkfs.vfat' (usually dosfstools) and try again."
  exit 1
fi

if [ -z "$BEAGLEBONE_SD" ]; then
  echo "Please set BEAGLEBONE_SD and try again."
  exit 1
fi

if [ ! -b "$BEAGLEBONE_SD" ]; then
  echo "$BEAGLEBONE_SD is not a block device or doesn't exist."
  exit 1
fi

IMAGES_DIR=$BUILDROOT_DIR/output/images
resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
ubootimg="$IMAGES_DIR/u-boot.bin"
ubootimgb="$IMAGES_DIR/u-boot-dtb.bin"
ubootimgc="$IMAGES_DIR/u-boot-sunxi-with-spl.bin"

if [ ! -f "$ubootimg" ]; then
  ubootimg=$ubootimgb
fi

if [ ! -f "$ubootimg" ]; then
  ubootimg=$ubootimgc
fi

if [ ! -f "$ubootimg" ]; then
  echo "can't find u-boot image at $ubootimg"
  exit 1
fi

if [ -z "$SKIFF_NO_INTERACTIVE" ]; then
  read -p "Are you sure? This will completely destroy all data. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

if [ -z "$SKIFF_NO_INTERACTIVE" ]; then
  read -p "Verify that '$BEAGLEBONE_SD' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

MKEXT4="mkfs.ext4 -F -O ^64bit"

set -x
set -e

echo "Formatting device..."
sudo parted $BEAGLEBONE_SD mklabel msdos

echo "Making boot partition..."
sudo parted -a optimal $BEAGLEBONE_SD mkpart primary fat32 2MiB 310MiB
sudo parted $BEAGLEBONE_SD set 1 boot on
sudo parted $BEAGLEBONE_SD set 1 lba on

BEAGLEBONE_SD_SFX=$BEAGLEBONE_SD
if [ -b ${BEAGLEBONE_SD}p1 ]; then
  BEAGLEBONE_SD_SFX=${BEAGLEBONE_SD}p
fi

mkfs.vfat -F 32 ${BEAGLEBONE_SD_SFX}1
fatlabel ${BEAGLEBONE_SD_SFX}1 boot

echo "Making rootfs partition..."
sudo parted -a optimal $BEAGLEBONE_SD mkpart primary ext4 310MiB 600MiB
$MKEXT4 -L "rootfs" ${BEAGLEBONE_SD_SFX}2

echo "Making persist partition..."
sudo parted -a optimal $BEAGLEBONE_SD -- mkpart primary ext4 600MiB "-1s"
$MKEXT4 -L "persist" ${BEAGLEBONE_SD_SFX}3

sync && sync
sleep 1

echo "Flashing u-boot..."
cd ${IMAGES_DIR}
dd iflag=dsync oflag=dsync if=$ubootimg of=$BEAGLEBONE_SD seek=8 bs=1024 ${SD_FUSE_DD_ARGS}

