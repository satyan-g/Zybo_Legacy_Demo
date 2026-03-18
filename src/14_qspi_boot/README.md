# 14 — QSPI Flash Boot — On Hold

Demonstrates the Zynq QSPI flash boot flow. The app runs a binary LED
counter and prints the boot mode register. Can be tested via JTAG, then
flashed to the on-board QSPI for standalone boot.

**Teaches:** QSPI boot image creation, bootgen, Zynq flash programming
via XSCT/program_flash, boot mode register.

**Status:** On hold — JTAG verified; QSPI flash programming untested.

## Build and Run
```
./scripts/build_hw.sh 14_qspi_boot
./scripts/build_sw.sh 14_qspi_boot
./scripts/deploy.sh 14_qspi_boot      # JTAG test
xsct src/14_qspi_boot/build_boot.tcl output/14_qspi_boot   # build BOOT.BIN
xsct src/14_qspi_boot/flash.tcl output/14_qspi_boot        # flash to QSPI
```

## What to Expect
- LEDs display a binary counter (0000 → 1111 → repeat).
- Serial console prints the boot mode register value.

## Source
- `src/14_qspi_boot/sw/qspi_boot_demo.c`
