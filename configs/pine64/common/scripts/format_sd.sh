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

if [ -z "$PINE64_SD" ]; then
  echo "Please set PINE64_SD and try again."
  exit 1
fi

if [ ! -b "$PINE64_SD" ]; then
  echo "$PINE64_SD is not a block device or doesn't exist."
  exit 1
fi

resources_path="${SKIFF_CURRENT_CONF_DIR}/resources"
ubootimg="$BUILDROOT_DIR/output/images/u-boot-sunxi-with-spl.bin"
ubootimg2="$BUILDROOT_DIR/output/images/u-boot.itb"
idbloader=""

if [ ! -f "$ubootimg" ]; then
    ubootimg=$ubootimg2
fi

rk3399fw="$BUILDROOT_DIR/output/images/rk3399-firmware-blobs"
if [ -d $rk3399fw ]; then
    ubootimg=$rk3399fw/u-boot.itb
    idbloader=$rk3399fw/idbloader.img
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
  read -p "Verify that '$PINE64_SD' is the correct device. Be sure. [y/N] " -n 1 -r
  echo
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

MKEXT4="mkfs.ext4 -F -O ^64bit"

set -x
set -e

echo "Formatting device..."
sudo dd if=/dev/zero of=$PINE64_SD bs=8k count=13 oflag=dsync

echo "Creating partitions..."
sudo partprobe ${PINE64_SD} || true
sudo parted $PINE64_SD mklabel msdos

# boot
sudo parted -a optimal $PINE64_SD mkpart primary fat32 128MiB 510MiB
sudo parted $PINE64_SD set 1 boot on
sudo parted $PINE64_SD set 1 lba on

# rootfs
sudo parted -a optimal $PINE64_SD mkpart primary ext4 510MiB 1024MiB

# persist
sudo parted -a optimal $PINE64_SD -- mkpart primary ext4 1024MiB "-1s"

echo "Waiting for partprobe..."
partprobe $PINE64_SD || true
sleep 2
partprobe $PINE64_SD || true

PINE64_SD_SFX=$PINE64_SD
if [ -b ${PINE64_SD}p1 ]; then
  PINE64_SD_SFX=${PINE64_SD}p
fi

if [ ! -b ${PINE64_SD_SFX}1 ]; then
    echo "Warning: it appears your kernel has not created partition files at ${PINE64_SD_SFX}."
fi

echo "Formatting boot partition..."
mkfs.vfat -F 32 ${PINE64_SD_SFX}1
fatlabel ${PINE64_SD_SFX}1 boot

echo "Formatting rootfs partition..."
$MKEXT4 -L "rootfs" ${PINE64_SD_SFX}2

echo "Formatting persist partition..."
$MKEXT4 -L "persist" ${PINE64_SD_SFX}3

sync && sync

echo "Flashing u-boot..."
if [ -n "$idbloader" ]; then
    # idbloader for rk3399 machines
    dd iflag=dsync oflag=dsync if=$idbloader of=$PINE64_SD seek=64 ${SD_FUSE_DD_ARGS}
    dd iflag=dsync oflag=dsync if=$ubootimg of=$PINE64_SD seek=16384 ${SD_FUSE_DD_ARGS}
else
    dd iflag=dsync oflag=dsync if=$ubootimg of=$PINE64_SD seek=8 bs=1024 ${SD_FUSE_DD_ARGS}
fi
cd -
