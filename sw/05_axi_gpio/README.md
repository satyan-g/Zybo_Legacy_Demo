# 05 — AXI GPIO

Reads switches and buttons through an AXI GPIO peripheral and drives LEDs.
Demonstrates PS-to-PL communication via the AXI interconnect.

## Hardware Setup
- AXI GPIO IP with two channels: ch1 = LEDs (output), ch2 = switches + buttons (input).
- Connected to Zynq PS via AXI interconnect.

## Build and Run
```
./scripts/build_hw.sh 05_axi_gpio
./scripts/build_sw.sh 05_axi_gpio
./scripts/deploy.sh 05_axi_gpio
```

## What to Expect
- LEDs mirror the switch/button state.
- Serial console prints input changes as they happen.

## Source
- `sw/05_axi_gpio/axi_gpio_demo.c`
