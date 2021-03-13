#!/bin/bash
set -eo pipefail

# NOTE: The following copyright applies to linux4tegra and associated tools:

# Copyright (c) 2019-2020, NVIDIA Corporation.  All Rights Reserved.
#
# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

# Note: this is called "flash_sd" and not "format_sd" because:
#  - "format": create partition layout, flash bootloader
#  - "flash": create partitions, flash everything incl. skiff and bootloader
# difference is "flash" combines "format" and "install" steps while overwriting data.

if [ $EUID != 0 ]; then
  echo "This script requires sudo, so it might not work."
fi

if [ -z "$NVIDIA_SD" ]; then
    echo "Please set NVIDIA_SD and try again."
    exit 1
fi

if [ ! -b "$NVIDIA_SD" ]; then
    echo "$NVIDIA_SD is not a block device or doesn't exist."
    exit 1
fi

IMAGES_DIR=$BUILDROOT_DIR/images
uimg_path=$IMAGES_DIR/Image
if [ ! -f "$uimg_path" ]; then
  echo "Image not found, make sure Buildroot is done compiling."
  exit 1
fi

l4t_tools_path=$IMAGES_DIR/linux4tegra/tools
if [ ! -d $l4t_tools_path ]; then
    echo "linux4tegra tools not found, ensure buildroot is done compiling."
    exit 1
fi

source ${SKIFF_CURRENT_CONF_DIR}/scripts/determine_config.sh
source ${nvidia_config_sh}

if [ -z "$boardid" ]; then
    echo "board id not set in nvidia board-params.sh"
    exit 1
fi

if [ -z "$target" ]; then
    echo "target not set in nvidia board-params.sh"
    exit 1
fi


l4t_dir=${IMAGES_DIR}/linux4tegra

rootfs_img=$IMAGES_DIR/rootfs.ext2
#rootfs_size=$(du -ms ${rootfs_img} | awk '{print $1}')
#rootfs_size=$((rootfs_size + (rootfs_size / 10)))
rootfs_size=2048

# TODO: flash ext4 image containing boot files + initrd image
# currently it flashes rootfs.ext2 which should instead be an initrd

echo "creating signed images"

bootloader_dir=${l4t_dir}/bootloader

pushd ${l4t_dir}
export BOARDID="${boardid}"
export FAB="${rev}"
# --bup
${l4t_dir}/flash.sh \
            --no-flash \
            --sign \
            --no-systemimg \
            -I $IMAGES_DIR/rootfs.ext2 \
            -K $IMAGES_DIR/u-boot-dtb.bin \
            -d $IMAGES_DIR/tegra210-p3448-0000-p3449-0000-b00.dtb \
            "${target}" "mmcblk0p1"
popd

signed_cfg="flash.xml"
signed_image_dir=${bootloader_dir}/signed
if [ ! -f "${signed_image_dir}/${signed_cfg}" ]; then
		echo "ERROR: ${signed_image_dir}/${signed_cfg} not found"
		exit 1
fi

echo "create partitions"
storage="sdcard"
partitions=($(${l4t_tools_path}/nvptparser.py "${signed_image_dir}/${signed_cfg}" "${storage}"))
part_type=8300 # Linux Filesystem

sgdisk -og "${NVIDIA_SD}"
for part in "${partitions[@]}"; do
		eval "${part}"
		if [ "${part_name}" = "master_boot_record" ]; then
			  continue
		fi
		part_size=$((${part_size} / 512)) # convert to sectors
		sgdisk -n "${part_num}":0:+"${part_size}" \
			     -c "${part_num}":"${part_name}" \
			     -t "${part_num}":"${part_type}" "${NVIDIA_SD}"
done

# prefer root partprobe
PARTPROBE=partprobe
if [ -f /usr/sbin/partprobe ]; then
    PARTPROBE=/usr/sbin/partprobe
fi

$PARTPROBE ${NVIDIA_SD} || true
sleep 1
if $PARTPROBE ${NVIDIA_SD}; then
    # wait for partitions to settle
    sleep 1
fi

echo "write partitions"
for part in "${partitions[@]}"; do
		eval "${part}"
		target_file=""
		if [ "${part_name}" = "APP" ]; then
        continue
			  # target_file="${IMAGES_DIR}/rootfs.ext2" # skiff blob
		elif [ -e "${signed_image_dir}/${part_file}" ]; then
			  target_file="${signed_image_dir}/${part_file}"
		elif [ -e "${bootloader_dir}/${part_file}" ]; then
			  target_file="${bootloader_dir}/${part_file}"
		fi

		echo "writing partition ${part_name}"
		if [ "${part_name}" = "master_boot_record" ]; then
			  echo "writing ${part_file}"
			  dd conv=notrunc conv=fsync if="${signed_image_dir}/${part_file}" of="${NVIDIA_SD}" bs="${part_size}" count=1
			  continue
		fi

		if [ "${target_file}" != "" ] && [ "${part_file}" != "" ]; then
			  echo "writing ${target_file}"
        target_part=${NVIDIA_SD}p${part_num}
        if [ ! -b ${target_part} ]; then
            target_part=${NVIDIA_SD}${part_num}
        fi
        if [ ! -b ${target_part} ]; then
            echo "Partition block device ${target_part} or ${NVIDIA_SD}p${part_num} does not exist!"
            exit 1
        fi
			  sudo dd conv=fsync if="${target_file}" of="${target_part}"
		fi
done

NVIDIA_SD_SFX=$NVIDIA_SD
if [ -b ${NVIDIA_SD}p1 ]; then
    NVIDIA_SD_SFX=${NVIDIA_SD}p
fi

echo "create persist partition"
mkfs.ext4 -F -O ^64bit -L "persist" ${NVIDIA_SD_SFX}1

