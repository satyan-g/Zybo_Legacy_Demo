# 03 — PWM Breathing LED (PL Only)

LED0 smoothly fades in and out using a PWM signal generated entirely in the PL.
Demonstrates basic PWM generation with a triangle-wave duty cycle.

## Hardware Setup
- PL only: 125 MHz clock on pin L16, LED0 on M14.
- No block design or PS configuration required.

## Build and Run
```
./scripts/build_hw.sh 03_breathing_led
./scripts/run_vivado.sh scripts/03_breathing_led/program.tcl
```

## What to Expect
- LED0 gradually brightens and dims in a continuous breathing pattern.
- No serial output (no PS).

## Source
- `src/03_breathing_led/breathing_led.v`
