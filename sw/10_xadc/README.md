# 10 — XADC On-Chip Sensors

Reads the Zynq's built-in XADC to report die temperature, VCCINT, and VCCAUX.
LEDs display a bar graph proportional to temperature.

## Hardware Setup
- XADC Wizard IP (or PS XADC access) connected via AXI interconnect.
- LEDs driven via AXI GPIO or direct PL connection for the bar graph.

## Build and Run
```
./scripts/build_hw.sh 10_xadc
./scripts/build_sw.sh 10_xadc
./scripts/deploy.sh 10_xadc
```

## What to Expect
- Serial console prints temperature (C), VCCINT (V), and VCCAUX (V) periodically.
- More LEDs light up as the die temperature increases.

## Source
- `sw/10_xadc/xadc_demo.c`
