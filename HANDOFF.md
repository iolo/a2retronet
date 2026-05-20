# Handoff

## Goal

Primary goal is now:

- `A2retroNET` targets `pico2` on `rp2350`
- SmartPort controller only
- USB thumb drive storage only
- No SSC mode
- No SD card support

## Current Status

The project now builds successfully via:

```sh
./build.sh
```

Current `build.sh`:

```sh
cmake -S . -B build -DPICO_BOARD=pico2 -DPICO_PLATFORM=rp2350
cmake --build build --config Release -j $(nproc)
```

This completes successfully in the current workspace.

## What Changed

### Build System

- [CMakeLists.txt](/home/iolo/workspace/retro/a2retronet/CMakeLists.txt)
  - Active ROM build no longer uses `6502/SSC.S`
  - `firmware.rom` is now generated from [6502/SMARTPORT.ROM.S](/home/iolo/workspace/retro/a2retronet/6502/SMARTPORT.ROM.S)
  - Build prefers a local `a2pico` checkout at `build/_deps/a2pico-src` to avoid network fetches
  - Utility/time support now comes from `new_sd_spi`
  - `pico_aon_timer` is linked for RP2350 timekeeping

### Firmware / Runtime

- [board.c](/home/iolo/workspace/retro/a2retronet/board.c)
  - SSC/Pascal/serial behavior has been removed from the Pico-side handling
  - Only SmartPort control/data paths remain active

- [main.c](/home/iolo/workspace/retro/a2retronet/main.c)
  - Runtime is host-only and runs `tuh_task()`

- [sp.c](/home/iolo/workspace/retro/a2retronet/sp.c)
  - SD/device-mode/SLIP fallback path removed
  - Operates only against mounted USB storage
  - Boot-drive remap bug fixed by returning a value on all paths in `adjust_boot()`

- [diskio.c](/home/iolo/workspace/retro/a2retronet/diskio.c)
  - Reduced to USB-only disk backend

- [hdd.c](/home/iolo/workspace/retro/a2retronet/hdd.c)
  - SD mount/init removed
  - Uses USB-only mount state
  - Now includes `my_rtc.h` from `new_sd_spi`

- [config.c](/home/iolo/workspace/retro/a2retronet/config.c)
  - Reads/writes `USB:/A2retroNET.txt`
  - Removed SD/USB media switching logic from config UI
  - Added safer path formatting in a few places
  - Rejects invalid boot selection `0`

- [tusb_config.h](/home/iolo/workspace/retro/a2retronet/tusb_config.h)
  - Device-mode config removed from active use

### New Utility Layer

- [new_sd_spi](/home/iolo/workspace/retro/a2retronet/new_sd_spi/)
  - `my_rtc.c` / `my_rtc.h` are used for RP2350-compatible timekeeping
  - `f_util.c` / `f_util.h` are used for FatFs helper functions

### ROM Image

- [6502/SMARTPORT.ROM.S](/home/iolo/workspace/retro/a2retronet/6502/SMARTPORT.ROM.S)
  - New SmartPort-only ROM source
  - Replaces the old mixed SmartPort+SSC ROM assembly path for active builds
  - Keeps the SmartPort slot ROM and banked handler structure needed by current firmware offsets

## Important Notes

### `pico2` and platform pairing

Earlier there was confusion about board/platform combinations.

Current working pair is:

```sh
-DPICO_BOARD=pico2 -DPICO_PLATFORM=rp2350
```

Using `pico2` with `rp2040` is invalid in the current Pico SDK.

### `a2pico` dependency

The build currently uses:

- `build/_deps/a2pico-src`

This avoids `FetchContent` failing when network access is unavailable.

If the local checkout disappears, CMake falls back to Git fetch.

### Timekeeping on RP2350

The old `sd_spi/src/rtc.c` depended on `hardware/rtc.h` and was not suitable for the current RP2350 build path.

Current active solution:

- `new_sd_spi/my_rtc.c`
- linked against `pico_aon_timer`
- `sd_spi/sd_driver/crc.c` is still compiled because `my_rtc.c` uses `crc7`

## What Is Left

### Cleanup

These files are still present and currently modified, but should be treated as dead code for the new direction unless someone explicitly wants to preserve SSC support elsewhere:

- [6502/SSC.S](/home/iolo/workspace/retro/a2retronet/6502/SSC.S)
- [6502/SSC.CN00.S](/home/iolo/workspace/retro/a2retronet/6502/SSC.CN00.S)
- [ser.c](/home/iolo/workspace/retro/a2retronet/ser.c)
- [ser.h](/home/iolo/workspace/retro/a2retronet/ser.h)
- [slip.c](/home/iolo/workspace/retro/a2retronet/slip.c)
- [slip.h](/home/iolo/workspace/retro/a2retronet/slip.h)
- [msc_device.c](/home/iolo/workspace/retro/a2retronet/msc_device.c)
- [usb_descriptors.c](/home/iolo/workspace/retro/a2retronet/usb_descriptors.c)

Recommended next cleanup:

1. Remove unused SSC/device-mode source files from the repository.
2. Revert or delete modifications in `6502/SSC.S` and `6502/SSC.CN00.S` if they are no longer needed.
3. Remove stale references in docs/comments that still imply dual-mode support.

### ROM Simplification

`6502/SMARTPORT.ROM.S` is now the active ROM source, but the firmware build path is still more complex than ideal.

Potential follow-up work:

1. Document ROM memory layout and why `OFFSET_NORMAL`, `OFFSET_BANK_1`, `OFFSET_BANK_2`, and `OFFSET_BANK_3` must stay aligned with the generated image.
2. Add a small verification step that checks `firmware.rom` generation more explicitly.
3. Consider shrinking or simplifying the ROM source if some compatibility entry points are no longer required.

### Documentation

Docs were updated at a high level, but should still be reviewed for stale wording:

- [README.md](/home/iolo/workspace/retro/a2retronet/README.md)
- [getting-started.md](/home/iolo/workspace/retro/a2retronet/getting-started.md)

Especially check for:

- references to old media types
- references to SSC mode
- references to SD card behavior

## Known Good Build Result

Successful command:

```sh
./build.sh
```

Current result:

- `A2retroNET.elf` builds successfully for `pico2` / `rp2350`

