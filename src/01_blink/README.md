# 01 — LED Blink (PL Only)

The simplest possible FPGA design. A 26-bit counter increments every clock
cycle; bit 25 toggles at ~1.86 Hz (125 MHz / 2^26), driving all 4 LEDs.
No block design, no ARM core, no software — just a counter and a clock.

**Teaches:** Verilog basics, clock-to-output path, Vivado non-project flow.

## Hardware Setup
- 125 MHz clock on pin L16, LEDs on M14/M15/G14/D18.

## Build and Run
```
./scripts/build_hw.sh 01_blink
./scripts/deploy.sh 01_blink
```

## What to Expect
- All 4 LEDs blink together at ~1 Hz. No serial output.

## Source
- `src/01_blink/hw/blink.v`
