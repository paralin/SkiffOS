# Intel Desktop

This configuration package contains (experimental) support for running SkiffOS
on a traditional desktop PC.

Additional kernel options are enabled to support a generic set of machines.
These modules should be disabled later to trim down the size of the OS.

The typical "boot" "rootfs" and "persist" partitions are reduced to a single
"skiffos" partition here.

## Setup

The setup process is currently a work in progress.

 1. Install "refind" with the "--alldrivers" option to EFI partition.
 2. Create a ext4 partition labeled "SKIFFOS"
 3. Create a "boot" directory and copy "refind_linux.conf" into it.
 4. Use `make cmd/apple/macbook/install` to install.

The install command copies to a file with the SkiffOS revision. Refind will
display all of the available SkiffOS versions to select for boot.
