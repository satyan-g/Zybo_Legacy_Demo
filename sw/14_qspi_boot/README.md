# 14 — QSPI Flash Boot

Binary counter on LEDs that can boot from QSPI flash.
Demonstrates the QSPI boot flow and boot mode register inspection.

## Hardware Setup
- Zynq PS with QSPI controller enabled.
- LEDs driven via EMIO or AXI GPIO.
- For QSPI boot: flash BOOT.BIN to QSPI, set boot jumper to QSPI.

## Build and Run
```
./scripts/build_hw.sh 14_qspi_boot
./scripts/build_sw.sh 14_qspi_boot
./scripts/deploy.sh 14_qspi_boot      # JTAG test
```
For QSPI boot, flash `BOOT.BIN` to the on-board QSPI.

## What to Expect
- LEDs display a binary counter pattern.
- Serial console prints the boot mode register value.

## Source
- `sw/14_qspi_boot/qspi_boot_demo.c`
