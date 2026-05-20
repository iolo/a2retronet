# A2retroNET

This project is based on [A2Pico](https://github.com/oliverschmidt/a2pico).

A2retroNET implements a SmartPort mass storage controller with up to eight drives. The supported disk image formats are ProDOS block images up to 32 MB, typically using the `.hdv`, `.po`, or `.2mg` file extensions.

This firmware targets A2Pico-lite hardware and uses a USB thumb drive as its only storage medium. SSC mode and Micro SD card support are not included.

## A2retroNET.uf2

This firmware operates as a USB-host SmartPort controller. A mounted USB thumb drive provides both the `A2retroNET.txt` configuration file and the disk image files referenced by that configuration.

Any change to the thumb drive state is detected by the Apple II in real time. The configuration utility also edits `A2retroNET.txt` directly on the thumb drive.

You can find the right adapter or cable to connect a USB thumb drive to A2Pico-lite by searching for "Micro USB OTG".

Please ensure the A2Pico-lite `USB Pwr` setting matches the hardware requirement for USB host operation.

## Boot Delay

While A2retroNET delays the boot, a countdown will be displayed in the lower right corner of the screen. The boot delay is configurable, and several keys are recognized.

| Key              | Command                                                            |
|:----------------:|--------------------------------------------------------------------|
| `C`              | Invoke the configuration utility                                   |
| `N`              | Continue the Apple II Autostart ROM slot search with the next slot |
| `1` - `8`        | Directly boot a drive by temporarily making it drive 1             |
| Any other key    | Skip the remaining boot delay                                      |

## Configuration Utility

The A2retroNET firmware contains a configuration utility. It can be invoked in two ways:

* By pressing the `C` key while A2retroNET delays the boot.

* By calling `$C<n>F0`:
  
  | A2retroNET Slot | BASIC Command |
  |:---------------:|:-------------:|
  | 1               | `CALL 49648`  |
  | 2               | `CALL 49904`  |
  | 3               | `CALL 50160`  |
  | 4               | `CALL 50416`  |
  | 5               | `CALL 50672`  |
  | 6               | `CALL 50928`  |
  | 7               | `CALL 51184`  |

The configuration utility provides a convenient way to edit the `A2retroNET.txt` configuration file directly from the Apple II.

<img src="/assets/config-iie.jpg" width="400"> <img src="/assets/config-iip.jpg" width="400">

The `Drive Configuration` screen allows you to configure which disk image file is used for which drive.

| Key              | Command                                                                  |
|:----------------:|--------------------------------------------------------------------------|
| `Esc`            | Quit the configuration utility                                           |
| `Space` or `Tab` | Toggle between selecting a drive and selecting a disk image file         |
| `Left` or `Up`   | Select previous drive or disk image file (or directory)                  |
| `Right`or `Down` | Select next drive or disk image file (or directory)                      |
| `Return`         | "Insert" selected disk image file in selected drive (or enter directory) |
| `-`              | "Remove" disk image file from selected drive                             |
| `/`              | Go to root directory                                                     |
| `1` - `8`        | Directly select a drive                                                  |
| `0` or `A` - `Z` | Directly select a disk image file (or directory) with a matching name    |
| `Ctrl-S`         | Enter `Settings` screen                                                  |

The `Settings` screen allows you to configure the boot delay in seconds and the number of drives provided by A2retroNET for the Apple II operating system. Additionally, the A2retroNET version is displayed.

| Key              | Command                                                      |
|:----------------:|--------------------------------------------------------------|
| `Esc`            | Go back to `Drive Configuration` screen                      |
| `Space` or `Tab` | Toggle between selecting a boot delay and a number of drives |
| `Left` or `Up`   | Select a smaller boot delay or number of drives              |
| `Right`or `Down` | Select a larger boot delay or number of drives               |
| `0` - `9`        | Directly select a boot delay or number of drives             |

### A2retroNET.txt

To use a storage device with A2retroNET, the text file `A2retroNET.txt` must be present in the root directory. This file is formatted like a conventional INI file. There are two sections: `[settings]` and `[drives]`.

The `[settings]` section contains the following entry type:

* `bootdelay` allows you to set the time in seconds to wait for a key press when booting A2retroNET before the actual boot process begins. Valid values are `0` to `9`. The default value is `3`.

The `[drives]` section contains the following entry types:

* `number` allows you to set the number of drives provided by A2retroNET for the Apple II operating system. Valid values are `2`, `4`, `6` and `8`. The default value is `8`.

* `1` through `8` indicate the name of the disk image to be used for the drive with the specified number.

A simple example:
```
[settings]
bootdelay=5
[drives]
number=4
1=system.hdv
2=work.hdv
3=utils.po
4=games.po
```

Valid formats for disk image names:
* `image.hdv`
* `/image.hdv` (same as above)
* `/path/to/image.hdv`
* `usb:image.hdv`
* `usb:/image.hdv` (same as above)
* `usb:/path/to/image.hdv`

Notes:
* No spaces are allowed around the `=`.
* A drive without an assigment is like a real drive with no media inserted. The same applies to assigning to a nonexistent disk image.
* A disk image with the file attribute Read-Only is used as write protected medium.
* Any line starting with `#` is considered a comment and ignored. This allows for quick switching between multiple assigments to the same drive by commenting out all but one.

## Error Handling

Accessing the A2retroNET SmartPort controller can result in an error for various reasons, including:
* Missing media
* Corrupted media
* Missing `A2retroNET.txt`
* Malformed `A2retroNET.txt`
* Missing disk image
* Corrupted disk image
* Write protected disk image

There are three distinct scenarios for accessing the A2retroNET SmartPort controller:
* The Apple II Autostart ROM searches slots 7 through 1 for a bootable device. If an error occurs, the search continues with the next slot.
* A boot operation is requested via `PR#<n>`. If an error occurs, the message `HDD ERROR` is displayed before returning to the BASIC prompt.
* ProDOS calls the SmartPort interface. If an error occurs, it is reported to ProDOS.
