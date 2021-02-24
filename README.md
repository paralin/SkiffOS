![](./resources/images/skiff.png)

## Introduction

Skiff compiles a lightweight operating system for [any Linux-compatible computer],
ranging from [RPi], [Odroid], [NVIDIA Jetson], to [Desktop PCs], Laptops (i.e.
[Apple MacBook]), [Phones] (PinePhone), Containers, or [Cloud VMs]. It is:

 - **Adoptable**: any userspace can be imported/exported to/from container images.
 - **Familiar**: uses simple Makefile and KConfig language for configuration.
 - **Flexible**: supports all major OS distributions inside containers.
 - **Portable**: containers can be moved between machines of similar CPU type.
 - **Reliable**: changes inside user environments cannot break the host boot-up.
 - **Reproducible**: a given Skiff Git tree will always produce identical output.

Uses [Buildroot] to produce a minimal "single-file" host OS as a standardized
base cross-platform operating system "shim" for hosting containers. Most Linux
platforms have widely varying requirements for kernel, firmware, and additional
hardware support packages. The immutable SkiffOS host system contains everything
needed to support the hardware, cleanly separated from the applications.

[any Linux-compatible computer]: https://linux-hardware.org/index.php?d=SkiffOS
[Apple MacBook]: https://linux-hardware.org/?probe=6dc90bec41
[Buildroot]: https://buildroot.org
[Cloud VMs]: https://imgur.com/a/PXCYnjT
[Desktop PCs]: https://linux-hardware.org/?probe=267ab5de51
[NVIDIA Jetson]: https://linux-hardware.org/?probe=184d1b1c05
[Odroid]: https://linux-hardware.org/?probe=927be03a24
[Phones]: https://linux-hardware.org/?probe=329e6f9308
[RPi]: https://linux-hardware.org/?probe=c3d8362f28

## Getting started

The `SKIFF_CONFIG` comma-separated environment variable selects which
configuration layers should be merged together to configure the build.

```sh
$ make                             # lists all available layers
$ export SKIFF_CONFIG=pi/4,skiff/core
$ make configure                   # configure the system
$ make compile                     # build the system
```

After you run `make configure` Skiff will remember what you selected in
`SKIFF_CONFIG`. The compile command instructs Skiff to build the system.

Adjustments can be made to configuration layers, and `make compile` can be
called again to re-pack the system image without re-building everything.

You can add your SSH public key to the target image by adding it to
`overrides/root_overlay/etc/skiff/authorized_keys/my-key.pub`, or by adding it
to your own custom configuration package.

The example above uses `pi/4`, which can be replaced with any of the hardware
support packages listed in the [Supported Systems](#supported-systems) table.

Once the build is complete, it's time to flash the system to a SD card. You will
need to switch to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
$ blkid                 # look for your SD card's device file
$ export PI_SD=/dev/sdz # make sure this is right!
$ make cmd/pi/common/format  # tell skiff to format the device
$ make cmd/pi/common/install # tell skiff to install the os
```

The device needs to be formatted only one time, after which, the install command
can be used to update the SkiffOS images without clearing the persistent state.
The persist partition is not touched in this step, so anything you save there,
including Docker state and system configuration, will not be modified.

There are many other utility commands made available by Buildroot, which can be
listed using `make br/help`, some examples:

```sh
$ make br/menuconfig # optionally explore Buildroot config
$ make br/sdk        # build relocatable SDK for target
$ make br/graph-size # graph the target packages sizes
```

Connect using SSH to `root@my-ip-address` to access the SkiffOS system, and
connect to `core@my-ip-address` to access the "Core" system container. The
mapping between users and containers can be edited in the
`/mnt/persist/skiff/core/config.yaml` file.

The system can then be upgraded over-the-air (OTA) using the rsync script:

```sh
$ ./scripts/push_image.bash root@my-ip-address
```

The SkiffOS upgrade (or downgrade) will take effect on next reboot.

## Supported Systems

![CI](https://github.com/skiffos/SkiffOS/workflows/CI/badge.svg?branch=master)

SkiffOS is based on Buildroot, which can compile operating systems for virtually
any machine. Therefore, SkiffOS also works on nearly any architecture or board.

Here are the boards/systems currently supported by Skiff:

| **Board**            | **Config Package** | **Bootloader**       | **Kernel**      | **Notes**              |
| ---------------      | -----------------  | -------------------- | --------------- | ---------------------- |
| [Docker Img]         | [virt/docker]      | N/A                  | N/A             | Run in Docker          |
| [Qemu]               | [virt/qemu]        | N/A                  | ✔ 5.11.1        | Run in QEmu            |
| [WSL] on Windows     | [virt/wsl]         | N/A                  | ✔ msft-5.4.72   | Run in WSL2            |
| [Apple Macbook]      | apple/macbook      | ✔ [rEFInd]           | ✔ 5.11.1        | ✔ Tested               |
| [BananaPi M1]        | bananapi/m1        | ✔ U-Boot 2020.10     | ✔ 5.11.1        | ⚠ Discontinued         |
| [BananaPi M1+/Pro]   | bananapi/m1plus    | ✔ U-Boot 2020.10     | ✔ 5.11.1        | ⚠ Discontinued         |
| [BananaPi M2+]       | bananapi/m2plus    | ✔ U-Boot 2020.10     | ✔ 5.11.1        |                        |
| [BananaPi M3]        | bananapi/m3        | ✔ U-Boot 2020.10     | ✔ 5.11.1        | ✔ Tested               |
| [Intel x86/64]       | intel/x64          | ✔ Grub               | ✔ 5.11.1        | ✔ Tested               |
| [LiteX VexRiscV]     | [litex/vexriscv]   | N/A                  | ✔ litex-5.11    | ⚠ In development       |
| [NVIDIA Jetson Nano] | [jetson/nano]      | ✔ U-Boot             | ✔ 4.9.140       | ✔ Tested               |
| [NVIDIA Jetson TX2]  | [jetson/tx2]       | ✔ U-Boot             | ✔ 4.9.140       | ✔ Tested               |
| [Odroid C2]          | [odroid/c2]        | ✔ U-Boot 2020.10     | ✔ tb-5.10.12    | ⚠ Discontinued         |
| [Odroid C4]          | [odroid/c4]        | ✔ U-Boot 2021.01     | ✔ tb-5.10.12    | ✔ Tested               |
| [Odroid U]           | [odroid/u]         | ✔ U-Boot 2016.03     | ✔ tb-5.10.12    | ⚠ Discontinued         |
| [Odroid HC1]         | [odroid/xu]        | ✔ U-Boot 2019.04     | ✔ tb-5.10.12    | ✔ Tested               |
| [Odroid HC2]         | [odroid/xu]        | ✔ U-Boot 2019.04     | ✔ tb-5.10.12    | ✔ Tested               |
| [Odroid XU3]         | [odroid/xu]        | ✔ U-Boot 2019.04     | ✔ tb-5.10.12    | ⚠ Discontinued         |
| [Odroid XU4]         | [odroid/xu]        | ✔ U-Boot 2019.04     | ✔ tb-5.10.12    | ✔ Tested               |
| [OrangePi Lite]      | orangepi/lite      | ✔ U-Boot 2018.05     | ✔ 5.11.1        |                        |
| [OrangePi Zero]      | orangepi/zero      | ✔ U-Boot 2018.07     | ✔ 5.11.1        |                        |
| [PcDuino 3]          | pcduino/3          | ✔ U-Boot 2019.07     | ✔ 5.11.1        |                        |
| [PcEngines APU2]     | pcengines/apu2     | ✔ CoreBoot           | ✔ 5.11.1        |                        |
| [Pi 0]               | [pi/0]             | N/A                  | ✔ rpi-5.10.14   | ✔ Tested               |
| [Pi 1]               | [pi/1]             | N/A                  | ✔ rpi-5.10.14   |                        |
| [Pi 3] + 1, 2        | [pi/3]             | N/A                  | ✔ rpi-5.10.14   | ✔ Tested               |
| [Pi 4]               | [pi/4]             | N/A                  | ✔ rpi-5.10.14   | ✔ Tested               |
| [Pine64] H64         | pine64/h64         | ✔ U-Boot             | ✔ pine64-5.8.0  | ✔ Tested               |
| [PineBook Pro]       | [pine64/book]      | ✔ U-Boot (bin)       | ✔ ayufan-5.9.0  | ✔ Tested               |
| [PinePhone]          | [pine64/phone]     | ✔ U-Boot             | ✔ megi-5.9.11   | ✔ Tested               |
| [RockPro64]          | pine64/rockpro64   | ✔ U-Boot (bin)       | ✔ 5.11.0-rc4    | ✔ Tested               |

[Apple Macbook]: https://wiki.gentoo.org/wiki/Apple_Macbook_Pro_Retina_(early_2013)
[BananaPi M1+/Pro]: http://linux-sunxi.org/LeMaker_Banana_Pi#Variants
[BananaPi M1]: http://linux-sunxi.org/LeMaker_Banana_Pi#Variants
[BananaPi M2+]: http://linux-sunxi.org/LeMaker_Banana_Pi#Variants
[BananaPi M3]: http://linux-sunxi.org/Banana_Pi_M3
[Docker Img]: ./docker 
[Intel x86/64]: ./configs/intel/x64
[NVIDIA Jetson Nano]: ./configs/jetson
[NVIDIA Jetson TX2]: ./configs/jetson
[Odroid C2]: https://wiki.odroid.com/odroid-c2/odroid-c2
[Odroid C4]: https://wiki.odroid.com/odroid-c4/odroid-c4
[Odroid HC1]: https://www.hardkernel.com/shop/odroid-hc1-home-cloud-one/
[Odroid HC2]: https://www.hardkernel.com/shop/odroid-hc2-home-cloud-two/
[Odroid U]: https://wiki.odroid.com/old_product/odroid-x_u_q/odroid_u3/odroid-u3
[Odroid XU3]: https://wiki.odroid.com/old_product/odroid-xu3/odroid-xu3
[Odroid XU4]: https://wiki.odroid.com/odroid-xu4/odroid-xu4
[OrangePi Lite]: http://linux-sunxi.org/Xunlong_Orange_Pi_One_%26_Lite
[OrangePi Zero]: http://linux-sunxi.org/Xunlong_Orange_Pi_Zero
[PcDuino 3]: https://linux-sunxi.org/LinkSprite_pcDuino3
[PcEngines APU2]: https://www.pcengines.ch/apu2.htm
[Pi 0]: https://www.raspberrypi.org/products/raspberry-pi-zero/
[Pi 1]: https://www.raspberrypi.org/products/raspberry-pi-1-model-b-plus/
[Pi 3]: https://www.raspberrypi.org/products/raspberry-pi-3-model-b/
[Pi 4]: https://www.raspberrypi.org/products/raspberry-pi-4-model-b/
[Pine64]: https://www.pine64.org/pine-h64-ver-b/
[PineBook Pro]: https://www.pine64.org/pinebook-pro/
[PinePhone]: https://www.pine64.org/pinephone/
[RockPro64]: https://www.pine64.org/rockpro64/
[rEFInd]: https://www.rodsbooks.com/refind/
[Qemu]: ./configs/virt/qemu
[WSL]: https://docs.microsoft.com/en-us/windows/wsl/

[virt/docker]: ./configs/virt/docker
[virt/qemu]: ./configs/virt/qemu
[virt/wsl]: ./configs/virt/wsl
[jetson/nano]: ./configs/jetson/nano
[jetson/tx2]: ./configs/jetson/tx2
[litex/vexriscv]: ./configs/litex/vexriscv
[odroid/c2]: ./configs/odroid
[odroid/c4]: ./configs/odroid
[odroid/u]: ./configs/odroid
[odroid/xu]: ./configs/odroid
[pi/0]: ./configs/pi
[pi/1]: ./configs/pi
[pi/3]: ./configs/pi
[pi/4]: ./configs/pi
[pine64/book]: ./configs/pine64/book
[pine64/phone]: ./configs/pine64/phone

All targets marked "tested" use automated end-to-end testing on real hardware.

Adding support for a board involves creating a Skiff configuration package for
the board, as described above. If you have a device that is not yet supported by
SkiffOS, please **[open an issue].**

[open an issue]: https://github.com/skiffos/SkiffOS/issues/new

## Skiff Core

[View Demo!](https://asciinema.org/a/RiWjwpTXMmK7d45TXjl0I20r9)

The Skiff Core subsystem, enabled with the `skiff/core` layer or by selecting
any of the core environment packages, automatically configures mappings between
users and containerized environments. It maps incoming SSH sessions accordingly:

 - Configured using a YAML configuration file `skiff-core.yaml`.
 - The container image is either pulled or built from scratch.
 - systemd and/or other init systems operate as PID 1 inside the container.

This allows virtually any workflow to be migrated to Skiff. The config file
structure is flexible, and allows for any number of containers, users, and
images to be defined and built.

### Supported Environments

Any existing GNU/Linux system with compatibility with the running kernel version
can be loaded as a Docker image with the `docker import` command.

All core configurations work with all target platforms:

| **Distribution**           | **Config Package**            | **Notes**                 |
| ---------------            | -----------------             | ----------------------    |
| [Gentoo]                   | core/gentoo                   | Based on latest stage3    |
| [NASA cFS] Framework       | [core/nasa_cfs]               | Flight software framework |
| [NASA Fprime] Framework    | [core/nasa_fprime]            | Flight software framework |
| [NixOS]                    | core/nixos                    |                           |
| [NixOS] for PinePhone      | core/pinephone_nixos          |                           |
| [NixOS] with [XFCE]        | core/nixos_xfce               |                           |
| [Ubuntu]                   | skiff/core                    | Default configuration     |
| PinePhone [KDE Neon]       | core/pinephone_neon           | Ubuntu-based KDE Neon     |
| PinePhone [Manjaro] KDE    | core/pinephone_manjaro_kde    | KDE Variant               |
| PinePhone [Manjaro] Lomiri | core/pinephone_manjaro_lomiri | Lomiri variant            |
| PinePhone [Manjaro] Phosh  | core/pinephone_manjaro_phosh  | Phosh variant             |
| PinePhone [UBPorts]        | core/pinephone_ubports        | Ubuntu-ports (legacy)     |

[Gentoo]: https://www.gentoo.org/
[KDE Neon]: https://neon.kde.org/
[Manjaro]: https://manjaro.org/
[NASA cFS]: https://github.com/nasa/cFS
[NASA Fprime]: https://github.com/nasa/fprime
[NixOS]: https://nixos.org
[UBPorts]: https://ubports.com/
[Ubuntu]: https://ubuntu.com/
[XFCE]: https://www.xfce.org/

[core/nasa_cfs]: ./configs/core/nasa_cfs
[core/nasa_fprime]: ./configs/core/nasa_fprime

The default configuration creates a user named "core" mapped into a container,
but this can be easily configured in the `skiff-core.yaml` configuration file:

```yaml
containers:
  core:
    image: skiffos/skiff-core-gentoo:latest
    [...]
users:
  core:
    container: core
    containerUser: core
    [...]
```

To customize the core configuration after booting into SkiffOS, edit the file at
`/mnt/persist/skiff/core/config.yaml`.

## Release Channels

There are three release channels: **next**, **master**, and **stable**.

Skiff can be upgraded or downgraded (rolled back) independently from the
persistent storage partition. This allows for easy OTA, and significant
improvements in confidence when upgrading system components.

## Configuration Packages/Layers

Skiff supports modular configuration packages. A configuration directory
contains kernel configs, buildroot configs, system overlays, etc.

These packages are denoted as `namespace/name`. For example, an ODROID XU4
configuration would be `odroid/xu`.

Configuration package directories should have a depth of 2, where the first
directory is the category name and the second is the package name.

### Package Layout

A configuration package is laid out into the following directories:

```
├── cflags:         compiler flags in files
├── buildroot:      buildroot configuration fragments
├── buildroot_ext:  buildroot extensions (extra packages)
├── buildroot_patches: extra Buildroot global patches
│   ├── <packagename>: patch files for Buildroot <packagename>
│   └── <packagename>/<version>: patches for package version
├── extensions:     extra commands to add to the build system
│   └── Makefile
├── hooks:          scripts hooking pre/post build steps
│   ├── post.sh
│   └── pre.sh
├── kernel:         kernel configuration fragments
├── kernel_patches: kernel .patch files
├── root_overlay:   root overlay files
├── metadata:       metadata files
│   ├── commands
│   ├── dependencies
│   ├── description
│   └── unlisted
├── resources:     files used by the configuration package
├── scripts:       any scripts used by the extensions
├── uboot:         u-boot configuration fragments
└── uboot_patches: u-boot .patch files
```

All files are optional.

### Out-of-tree configuration packages

You can set the following env variables to control this process:

 - `SKIFF_CONFIG_PATH_ODROID_XU`: Set the path for the ODROID_XU config package. You can set this to add new packages or override old ones.
 - `SKIFF_EXTRA_CONFIGS_PATH`: Colon separated list of paths to look for config packages.
 - `SKIFF_CONFIG`: Name of skiff config to use, or comma separated list to overlay, with the later options taking precedence

These packages will be available in the Skiff system.

### Local Overrides

It's often useful to be able to adjust the buildroot, kernel, or other
configurations locally during development without actually creating a new
configuration layer. This can be easily done with the overrides system.

The `overrides` directory, as well as the
`overrides/workspaces/$SKIFF_WORKSPACE` directory, are automatically used as
additional Skiff configuration packages. You can follow the Skiff configuration
package format as defined below to override any of the settings in Buildroot or
the Linux kernel, add extra Buildroot packages, add build hooks, etc.

## Workspaces

Workspaces allow you to configure and compile multiple systems at a time.

Set `SKIFF_WORKSPACE` to the name of the workspace you want to use. The
Buildroot setup will be constructed in `workspaces/$SKIFF_WORKSPACE`. You can
also place configuration files in `overrides/workspaces/$SKIFF_WORKSPACE/` to
override settings for that particular workspace locally.

## Virtualization

The virt/ packages are designed for running Skiff in various virtualized environments.

### Qemu

Here is a minimal working example of running Skiff in Qemu:

```sh
$ SKIFF_CONFIG=virt/qemu make configure compile
$ make cmd/virt/qemu/run
```

### Docker

Here is a minimal working example of running Skiff in Docker:

```sh
$ SKIFF_CONFIG=virt/docker,skiff/core make configure compile
$ make cmd/virt/docker/buildimage
$ make cmd/virt/docker/run

# inside container
$ su - core
```

The build command compiles the image, and run executes it.

You can execute a shell inside the container with:

```sh
$ make cmd/virt/docker/exec
# alternatively
$ docker exec -it skiff sh
```

## Configuration

SkiffOS includes a systemd-based configuration and a standard partition layout,
with boot files separated from the persistent data, on default. This can be
disabled, overridden, and/or customized by other configuration packages.

### NetworkManager

Skiff uses NetworkManager to manage network connections.

Network configurations are loaded from `/etc/NetworkManager/system-connections`
and from `skiff/connections` on the persist partition.

The configuration file format for these connections is [documented
here](http://manpages.ubuntu.com/manpages/wily/man5/nm-settings-keyfile.5.html)
with examples.

You can use `nmcli` on the device to manage `NetworkManager`, and any connection
definitions written by `nmcli device wifi connect` or similar will automatically
be written to the persist partition and persisted to future boots.

### Hostname

You can set the hostname by placing the desired hostname in the `skiff/hostname`
file on the persist partition. You could also set this in one of your config
packages by writing the desired hostname to `/etc/hostname`.

### SSH Keys

The system on boot will generate the authorized_keys file for root.

It takes SSH public key files (`*.pub`) from these locations:

 - `/etc/skiff/authorized_keys` from inside the image
 - `skiff/keys` from inside the persist partition

## Build in Docker

You can [build Skiff inside Docker](./build/docker) if you encounter any
incompatibility with your build host operating system.

## Support

If you encounter issues or questions at any point when using Skiff, please file
a [GitHub issue](https://github.com/skiffos/SkiffOS/issues/new) and/or [Join
Discord](https://discord.gg/EKVkdVmvwT).
