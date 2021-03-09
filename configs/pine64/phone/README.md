# Pine64 PinePhone

This configuration package `pine64/phone` compiles a Skiff base operating system
for the Pine64 PinePhone. Most of the other distributions are available as core
configurations.

References: 

 - https://linux-sunxi.org/PinePhone
 - https://wiki.pine64.org/index.php?title=PinePhone 
 - https://www.ironrobin.net/pureos/git/clover/pinephone
 - https://gitlab.com/groups/postmarketOS/-/milestones/1
 - https://gitlab.com/postmarketOS/pmaports/-/tree/master/device/community/device-pine64-pinephone
 - https://xnux.eu/devices/pine64-pinephone.html

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=pine64/phone,core/pinephone_ubtouch
$ make configure                   # configure the system
$ make compile                     # build the system
```

The `core/pinephone_ubtouch` portion of SKIFF_CONFIG enables "Skiff Core" with
[Ubuntu Touch] for PinePhone. See http://ubuntu-touch.io for more information.

Once the build is complete, it's time to flash the system. There are several
approaches, please see the "Flashing" section in the [common readme].

[common readme]: ../
[Ubuntu Touch]: https://devices.ubuntu-touch.io/device/pinephone

## Skiff Core: Available Variants


| **Distribution**           | **Config Package**            | **Notes**              |
| ---------------            | -----------------             | ---------------------- |
| PinePhone [KDE Neon]       | core/pinephone_neon           | Ubuntu-based KDE Neon  |
| PinePhone [Manjaro] KDE    | core/pinephone_manjaro_kde    | KDE Variant            |
| PinePhone [Manjaro] Lomiri | core/pinephone_manjaro_lomiri | Lomiri variant         |
| PinePhone [Manjaro] Phosh  | core/pinephone_manjaro_phosh  | Phosh variant          |
| PinePhone [UBTouch]        | core/pinephone_ubtouch        | Ubuntu Touch           |


[KDE Neon]: https://neon.kde.org/
[Manjaro]: https://manjaro.org/
[UBPorts]: https://ubuntu-touch.io/

## Using Jumpdrive

Flashing using the micro "Jumpdrive" image is useful for recovery:

 1. Download the [Jumpdrive image]. 2. Flash&boot to a SD card: `xzcat jumpdrive.xz | dd of=/dev/sdx`
 3. Connect to PC over USB.
 4. The internal EMMC will appear as a new disk.

The disk now exists at, for example, `/dev/sdc`. Use the [flashing](../)
commands to flash SkiffOS to the EMMC.

[Jumpdrive image]: https://github.com/dremurrs-embedded/Jumpdrive/releases

## Upgrading Modem Firmware

The phone comes with a older version of the firmware pre-flashed to the modem.
To upgrade the modem firmware, follow the instructions on the [PinePhone
Firmware Wiki] page.

Reference:

 - [PinePhone Firmware Wiki]
 - https://github.com/Biktorgj/quectel_eg25_recovery
 - https://github.com/Biktorgj/qfirehose
 - https://git.sr.ht/~martijnbraam/pinephone-modemfw/

[PinePhone Firmware Wiki]: https://wiki.pine64.org/wiki/PineModems#Firmware_Recovery

