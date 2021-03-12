# Skiff Core based on Ubuntu Touch for PinePhone

This is the Ubuntu Touch configuration for SkiffOS Core.

https://gitlab.com/ubports/community-ports/pinephone#how-do-i-install-ubuntu-touch-on-my-pinephone

## Rebuilding the Base Image

To build the base image:

Fetch the latest download: https://ci.ubports.com/job/rootfs/job/rootfs-pinephone-systemimage/lastSuccessfulBuild/artifact/ubuntu-touch-pinephone.img.xz

Then, mount it as a loop-back device, and build the docker image:

```sh
  xz -d ./ubuntu-touch-pinephone.img.xz
  mkdir mtpt
  losetup -P /dev/loop2 ./ubuntu-touch-pinephone.img
  mount /dev/loop2p9 ./mtpt
  cd mtpt
  tar -c . | docker import - skiffos/pinephone-ubtouch-base:latest
  cd ..
  umount mtpt
  mount /dev/loop2p10 ./mtpt
  rsync -rav ./mtpt/ ./userdata/
  umount ./mtpt
  
  losetup -d /dev/loop2
  
  # alternatively, if partitions are not detected:
  # fdisk -l ./ubuntu-touch-pinephone.img
  # multiply partition start by 512
  # losetup -o 2840000512 /dev/loop2 ./ubuntu-touch-pinephone.img
  # mount /dev/loop2 ./mtpt
```

The contents of userdata/ and android/ are expected to be in the working
directory when running `docker build` below.

Next, build `skiffos/skiff-core-pinephone-ubtouch:latest`:


```sh
cd /opt/skiff/coreenv/skiff-core-ubtouch
docker build -t skiffos/skiff-core-pinephone-ubtouch:latest .
```

Finally, restart skiff-core to apply the changes:

```sh
docker rm -f core
systemctl restart skiff-core
```

