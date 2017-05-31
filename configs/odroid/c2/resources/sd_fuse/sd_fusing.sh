#!/bin/sh
#
# Copyright (C) 2015 Hardkernel Co,. Ltd
# Dongjin Kim <tobetter@gmail.com>
#
# SPDX-License-Identifier:	GPL-2.0+
#

BL1=bl1.bin.hardkernel
UBOOT=$2

if [ -z $1 ]; then
        echo "Usage ./sd_fusing.sh <SD card reader's device> <uboot path>"
        exit 1
fi

if [ ! -f $BL1 ]; then
        echo "error: $BL1 does not exist"
        exit 1
fi

if [ ! -f $UBOOT ]; then
        echo "error: $UBOOT does not exist"
        exit 1
fi

sudo dd if=$BL1 of=$1 conv=fsync bs=1 count=442 ${SD_FUSE_DD_ARGS}
sudo dd if=$BL1 of=$1 conv=fsync bs=512 skip=1 seek=1 ${SD_FUSE_DD_ARGS}
sudo dd if=$UBOOT of=$1 conv=fsync bs=512 seek=97 ${SD_FUSE_DD_ARGS}

sync

echo Finished.
