# 04 — Switches and Buttons (PL Only)

Slide switches and push buttons directly control the LEDs through PL logic.
Demonstrates basic combinational I/O without any processor involvement.

## Hardware Setup
- PL only: switches (G15/P15/W13/T16), buttons (R18/P16/V16/Y16), LEDs (M14/M15/G14/D18).
- No block design or PS configuration required.

## Build and Run
```
./scripts/build_hw.sh 04_switches_buttons
./scripts/run_vivado.sh scripts/04_switches_buttons/program.tcl
```

## What to Expect
- Each switch and button directly controls its corresponding LED.
- No serial output (no PS).

## Source
- `src/04_switches_buttons/switches_buttons.v`
