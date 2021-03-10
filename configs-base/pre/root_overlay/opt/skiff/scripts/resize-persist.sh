#!/bin/bash
# set -eo pipefail

PRE_SCRIPTS_DIR=/opt/skiff/scripts/mount-all.pre.d
# Run any additional pre setup scripts.
# We source these to allow overriding the above variables.
for i in ${PRE_SCRIPTS_DIR}/*.sh ; do
    if [ -r $i ]; then
        source $i
    fi
done

if [ -n "$PERSIST_RESIZE_DEVICE" ]; then
    PERSIST_DEVICE=$PERSIST_RESIZE_DEVICE
fi

if [ -n "$PERSIST_DEVICE" ]; then
    PERSIST_DEV=$(blkid | grep ${PERSIST_DEVICE}: | head -n1 | cut -d: -f1)
fi
if [ -z "$PERSIST_DEV" ]; then
    PERSIST_DEV=/dev/disk/by-label/persist
fi
# HACK: better would be a systemd pre-condition.
# this script is in boot-up critical path, which makes things complicated.
if [ ! -b "$PERSIST_DEV" ]; then
    echo "Cannot find persist device, will retry in a moment..."
    sleep 2
fi
if [ ! -b "$PERSIST_DEV" ]; then
    echo "Cannot find persist device, skipping check."
    echo "PERSIST_DEVICE=${PERSIST_DEVICE}"
    echo "PERSIST_DEV=${PERSIST_DEV}"
    exit 0
fi
PERSIST_DEV=$(readlink -f $PERSIST_DEV)

echo "Found persist partition at ${PERSIST_DEV}, performing filesystem check if necessary..."
FSCKFIX=yes fsck -y $PERSIST_DEV

PARTNAME=$(basename $PERSIST_DEV)
PARTLINE=$(cat /proc/partitions | grep $PARTNAME)
DEVMAJOR=$(echo $PARTLINE | awk '{print $1}')
DEVMINOR=$(echo $PARTLINE | awk '{print $2}')
DEVNAME=$(cat /proc/partitions | grep " $DEVMAJOR " | head -n1 | awk '{print $4}')
DEVPATH=/dev/$DEVNAME
echo "Disk partition detected ${DEVPATH}"
if [ ! -b $DEVPATH ]; then
    echo "Cannot find disk at $DEVPATH - continuing"
    exit 0
fi
disk=$DEVPATH
echo "Disk detected at ${disk}."
part_num=$DEVMINOR
echo "Partition number detected as $part_num"
disk_part=$PERSIST_DEV
p2_start=$(fdisk -l $disk -o "DEVICE,START" | grep -w $disk_part | awk '{print $2}' | tr -d '[[:space:]]')
echo "Partition start: $p2_start"
p2_end=$(fdisk -l $disk -o "DEVICE,END" | grep -w $disk_part | awk '{print $2}' | tr -d '[[:space:]]')
echo "Partition end: $p2_end"
disk_size=$(blockdev --getsize $disk)
echo "Disk size: $disk_size"

if [ ! $(( $disk_size - $p2_end )) -ge 10485760 ]; then
  echo "No need to resize physical, exiting."
  if ! resize2fs ${disk_part} ; then
      echo "[ignored]"
  fi
  exit 0
fi


echo "Resizing $disk_part from $p2_end to $p2_new_end"

# p2_new_end=$((disk_size-10))
# allow fdisk to select the endpoint by sending -10
# $p2_new_end

set +e
fdisk $disk <<EOF
p
d
$part_num
n
p
$part_num
$p2_start
-10
N


p
w
EOF

echo "Resized persist partition, resizing ext4 filesystem to partition."
resize2fs ${disk_part}

