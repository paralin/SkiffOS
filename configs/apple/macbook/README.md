# Apple Macbook (Intel)

This package supports the Intel Macbook Pros.

It is tested on the MacBookPro 12,1 but should work with any amd64.

## Setup

The configuration / setup process is a work in progress:

 1. Install "refind" with the "--alldrivers" option from the recovery mode.
 2. Use Recovery Mode and Disk Utility to create a SKIFFOS fat32 partition.
 3. Using mkfs.ext4, setup an ext4 filesystem on the partition.
 4. Label the filesystem "skiffos"
 5. Create a "boot" directory and copy "refind_linux.conf" into it.
 6. Use `make cmd/apple/macbook/install` to install.
       
The install command copies to a file with the SkiffOS revision. Refind will 
display all of the available SkiffOS versions to select for boot.
