# 01 — LED Blink (PL Only)

All 4 LEDs blink at approximately 1 Hz using a 26-bit counter in the PL.
No ARM core involvement — pure programmable logic.

## Hardware Setup
- PL only: 125 MHz clock on pin L16, LEDs on M14/M15/G14/D18.
- No block design or PS configuration required.

## Build and Run
```
./scripts/build_hw.sh 01_blink
./scripts/run_vivado.sh scripts/01_blink/program.tcl
```

## What to Expect
- All 4 LEDs blink together at ~1 Hz.
- No serial output (no PS).

## Source
- `src/01_blink/blink.v`
