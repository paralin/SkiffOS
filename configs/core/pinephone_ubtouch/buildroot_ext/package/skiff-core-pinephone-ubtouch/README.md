# Skiff Core based on Ubuntu Touch for PinePhone

This is the Ubuntu Touch configuration for SkiffOS Core.

https://gitlab.com/ubports/community-ports/pinephone#how-do-i-install-ubuntu-touch-on-my-pinephone

## Rebuilding the Base Image

To build the base image:

Fetch the latest download: https://ci.ubports.com/job/rootfs/job/rootfs-pinephone-systemimage/lastSuccessfulBuild/artifact/ubuntu-touch-pinephone.img.xz

Then, mount it as a loop-back device, and build the docker image:

```sh
  xz -d ./ubuntu-touch-pinephone.img.xz
  losetup -o 2840000512 /dev/loop2 ./ubuntu-touch-pinephone.img
  mkdir mtpt
  # mount /dev/loop2p9 ./mtpt
  mount /dev/loop2 ./mtpt
  cd mtpt
  tar -c . | docker import - skiffos/pinephone-ubtouch-base:latest
  cd ..
  umount mtpt
  losetup -d /dev/loop2
```

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

