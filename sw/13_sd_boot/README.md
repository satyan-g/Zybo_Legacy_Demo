# 13 — SD Card Boot

Knight Rider (Larson scanner) LED chaser that can boot from SD card.
Demonstrates the SD boot flow and boot mode register inspection.

## Hardware Setup
- Zynq PS with SD0 controller enabled.
- LEDs driven via EMIO or AXI GPIO.
- For SD boot: format FAT32, copy BOOT.BIN to card, set boot jumper to SD.

## Build and Run
```
./scripts/build_hw.sh 13_sd_boot
./scripts/build_sw.sh 13_sd_boot
./scripts/deploy.sh 13_sd_boot        # JTAG test
```
For SD boot, generate `BOOT.BIN` and place it on the SD card.

## What to Expect
- LEDs show a Knight Rider back-and-forth chaser pattern.
- Serial console prints the boot mode register value.

## Source
- `sw/13_sd_boot/sd_boot_demo.c`
