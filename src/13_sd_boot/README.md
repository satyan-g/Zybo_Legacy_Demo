# 13 — SD Card Boot

Demonstrates the Zynq SD boot flow. The app itself runs a Knight Rider
(Larson scanner) LED chaser and prints the boot mode register (BOOT_MODE_USER
at 0xF8000244) so you can verify which boot source was used. Can be tested
via JTAG first, then deployed as a self-contained BOOT.BIN on an SD card.

**Teaches:** FSBL + bitstream + app boot image (BIF format), bootgen,
FAT32 SD card setup, Zynq boot mode register.

## Build and Run
```
./scripts/build_hw.sh 13_sd_boot
./scripts/build_sw.sh 13_sd_boot
./scripts/deploy.sh 13_sd_boot        # JTAG test
xsct src/13_sd_boot/build_boot.tcl output/13_sd_boot   # build BOOT.BIN
```
Copy `output/13_sd_boot/BOOT.BIN` to a FAT32 SD card, set the boot jumper to SD.

## What to Expect
- LEDs scan back and forth (Knight Rider pattern).
- Serial console prints the boot mode register value.

## Source
- `src/13_sd_boot/sw/sd_boot_demo.c`
