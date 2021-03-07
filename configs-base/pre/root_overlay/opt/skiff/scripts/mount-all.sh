#!/bin/sh

PERSIST_DEVICE="LABEL=persist"
ROOTFS_DEVICE="LABEL=rootfs"
PERSIST_SUBDIR=/
ROOTFS_SUBDIR=/
SYSTEMD_CONFD=/etc/systemd/system
PERSIST_MNT=/mnt/persist
ROOTFS_MNT=/mnt/rootfs
SKIP_MOUNT_FLAG=/etc/skip-skiff-mounts
SKIP_JOURNAL_FLAG=/etc/skip-skiff-journal-mounts
PRE_SCRIPTS_DIR=/opt/skiff/scripts/mount-all.pre.d
EXTRA_SCRIPTS_DIR=/opt/skiff/scripts/mount-all.d

# Run any additional pre setup scripts.
# We source these to allow overriding the above variables.
export SKIFF_RUN_INIT_ACTIONS="true"
for i in ${PRE_SCRIPTS_DIR}/*.sh ; do
    if [ -r $i ]; then
        source $i
    fi
done

# Ensure that / is mounted read-write if applicable
if [ -z "$DISABLE_ROOT_REMOUNT_RW" ]; then
    READ_ONLY_MOUNTS=$(awk '$4~/(^|,)ro($|,)/' /proc/mounts)
    if echo "${READ_ONLY_MOUNTS}" | grep -q "/ rootfs ro"; then
        echo "Remounting / read-write..."
        mount -o remount,rw / || true
    fi
fi

PERSIST_ROOT=$PERSIST_MNT/$PERSIST_SUBDIR
SKIFF_PERSIST=$PERSIST_ROOT/skiff
KEYS_PERSIST=$SKIFF_PERSIST/keys
SSH_PERSIST=$SKIFF_PERSIST/ssh
JOURNAL_PERSIST=$SKIFF_PERSIST/journal
SKIFF_RELEASE_FILE=/etc/skiff-release

overlay_workdir=${PERSIST_ROOT}/skiff-overlays

if [ -f $SKIFF_RELEASE_FILE ]; then
    BUILD_DATE=$(cat /etc/skiff-release  | grep BUILD_DATE | cut -d\" -f2)
    BUILD_DATE_UTC=$(date --utc --date="$BUILD_DATE" +%s)
    CURRENT_DATE_UTC=$(date --utc +%s)
    if (( $BUILD_DATE_UTC > $CURRENT_DATE_UTC )); then
        echo "Build date of ${BUILD_DATE} is newer than internal clock of $(date). Bumping internal clock to build date."
        date -s "$BUILD_DATE" || true
    fi
fi

DOCKER_SERVICE=/usr/lib/systemd/system/docker.service
DOCKER_CONFD=/etc/systemd/system/docker.service.d
DOCKER_PERSIST=$SKIFF_PERSIST/docker

# Grab the default docker execstart
if [ -f $DOCKER_SERVICE ]; then
    DOCKER_EXECSTART=$(cat $DOCKER_SERVICE | grep '^ExecStart=.*$' | sed -e "s/ExecStart=//")
fi

mkdir -p $SYSTEMD_CONFD
mkdir -p $DOCKER_CONFD
# echo "Mounting persist partition
mkdir -p $PERSIST_MNT
if [ -f $SKIP_MOUNT_FLAG ] || mountpoint -q $PERSIST_MNT || mount $PERSIST_MNT_FLAGS $PERSIST_DEVICE $PERSIST_MNT; then
  echo "Persist drive is at $PERSIST_MNT path $PERSIST_ROOT"
  mkdir -p $PERSIST_ROOT/internal
  mkdir -p $SKIFF_PERSIST
  mkdir -p $DOCKER_PERSIST
  mkdir -p $JOURNAL_PERSIST
  mkdir -p $SSH_PERSIST
  if [ -f $DOCKER_SERVICE ]; then
    echo "Configuring Docker to use $DOCKER_PERSIST"
    DOCKER_EXECSTART+=" --data-root=\"$DOCKER_PERSIST\""

    echo "Configuring Docker to use systemd-journald"
    DOCKER_EXECSTART+=" --log-driver=journald"
  fi

  if [ ! -f $SKIP_JOURNAL_FLAG ] && ! mountpoint -q /var/log/journal ; then
    echo "Configuring systemd-journald to use $JOURNAL_PERSIST"
    if [ -d /var/log/journal ]; then
     rm -rf /var/log/journal || true
    fi
    mkdir -p /var/log/journal
    mount --bind ${JOURNAL_PERSIST} /var/log/journal
    chmod 4755 /var/log/journal
    systemd-tmpfiles --create --prefix /var/log/journal || true
  fi

  if [ ! -f $SSH_PERSIST/sshd_config ]; then
    cp /etc/ssh/sshd_config $SSH_PERSIST/sshd_config
  fi
  if [ ! -f $SSH_PERSIST/ssh_config ]; then
    cp /etc/ssh/ssh_config $SSH_PERSIST/ssh_config
  fi
  if ! mountpoint -q /etc/ssh; then
    mount --bind $SSH_PERSIST /etc/ssh
  fi
else
  echo "Unable to find drive ${PERSIST_DEVICE}!"
  mkdir -p /var/log/journal
fi

mkdir -p $ROOTFS_MNT
if [ -f $SKIP_MOUNT_FLAG ] || mountpoint -q $ROOTFS_MNT || mount $ROOTFS_MNT_FLAGS $ROOTFS_DEVICE $ROOTFS_MNT; then
  echo "Rootfs drive at $ROOTFS_MNT"
else
  echo "Unable to find drive ${ROOTFS_DEVICE}!"
fi

if [ -f $DOCKER_SERVICE ]; then
  echo "Configuring Docker to start with '$DOCKER_EXECSTART'"
  printf "[Service]\nExecStart=\nExecStart=$DOCKER_EXECSTART" > $DOCKER_CONFD/execstart.conf
fi

echo "Building SSH key list..."
mkdir -p $KEYS_PERSIST
echo "Put your SSH keys (*.pub) here." > $KEYS_PERSIST/readme
mkdir -p /tmp/skiff_ssh_keys
mkdir -p /root/.ssh
touch /root/.ssh/authorized_keys
cp $KEYS_PERSIST/*.pub /tmp/skiff_ssh_keys 2>/dev/null || true
cp /etc/skiff/authorized_keys/*.pub /tmp/skiff_ssh_keys 2>/dev/null || true
if [ "$(ls -A /tmp/skiff_ssh_keys)" ]; then
  cat /tmp/skiff_ssh_keys/*.pub > /root/.ssh/authorized_keys
else
  echo "No ssh keys present."
fi
rm -rf /tmp/skiff_ssh_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

mkdir -p /etc/NetworkManager/system-connections
if ! mountpoint /etc/NetworkManager/system-connections ; then
  mkdir -p $PERSIST_ROOT/skiff/connections
  echo "# Place NetworkManager keyfile configs here." > $PERSIST_ROOT/skiff/connections/readme
  # chmod all files to 0600 or NetworkManager will not read them.
  chmod 600 ${PERSIST_ROOT}/skiff/connections/*
  mkdir -p /etc/NetworkManager/system-connections
  connections_workdir=${overlay_workdir}/nm_connections
  mkdir -p $connections_workdir
  mount -t overlay -o lowerdir=/etc/NetworkManager/system-connections,upperdir=${PERSIST_ROOT}/skiff/connections,workdir=$connections_workdir overlay /etc/NetworkManager/system-connections
fi
chmod 0755 /etc/NetworkManager
chmod 0644 /etc/NetworkManager/NetworkManager.conf
chmod -R 0600 /etc/NetworkManager/system-connections
chown -R root:root /etc/NetworkManager/system-connections

if [ -d $PERSIST_ROOT/skiff/etc ]; then
  rsync -rav $PERSIST_ROOT/skiff/etc/ /etc/
else
  mkdir -p $PERSIST_ROOT/skiff/etc/
fi
echo "Place etc overrides here." > $PERSIST_ROOT/skiff/etc/readme

if [ -f $PERSIST_ROOT/skiff/hostname ] && [ -n "$(cat ${PERSIST_ROOT}/skiff/hostname)" ]; then
  OHOSTNAME=$(cat /etc/hostname)
  if [ -z "$OHOSTNAME" ]; then
      OHOSTNAME=skiff-unknown
  fi
  NHOSTNAME=$(cat $PERSIST_ROOT/skiff/hostname)
  sed -i -e "s/$OHOSTNAME/$NHOSTNAME/g" /etc/hosts
  echo "$NHOSTNAME" > /etc/hostname

else
  hostname > $PERSIST_ROOT/skiff/hostname
  if [ "$(hostname)" == "" ]; then
      "skiff-unknown" > $PERSIST_ROOT/skiff/hostname
  fi
fi

systemctl daemon-reload
hostname -F /etc/hostname # change transient hostname

# Run any additional final setup scripts.
for i in ${EXTRA_SCRIPTS_DIR}/*.sh ; do
    if [ -r $i ]; then
        if ! $i ; then
            echo "Script at $i failed! Ignoring."
        fi
    fi
done

# Probe udev to make sure any new kernel modules are picked up.
systemctl restart --no-block systemd-udev-trigger.service || true
