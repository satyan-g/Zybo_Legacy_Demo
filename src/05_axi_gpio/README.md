# 05 — AXI GPIO

The ARM core reads switches and buttons and writes LED patterns through an
AXI GPIO peripheral — the first PS↔PL communication example. Two AXI GPIO
channels: ch1 drives LEDs (output), ch2 reads SW[3:0]+BTN[3:0] (input).
The app polls every 200 ms and prints changes to the serial console.

**Teaches:** AXI GPIO IP, Zynq block design, PS↔PL memory-mapped I/O,
XGpio driver, XPAR_*_BASEADDR addressing.

## Build and Run
```
./scripts/build_hw.sh 05_axi_gpio
./scripts/build_sw.sh 05_axi_gpio
./scripts/deploy.sh 05_axi_gpio
```

## What to Expect
- LEDs mirror the switch/button state.
- Serial console prints whenever switches or buttons change.

## Source
- `src/05_axi_gpio/sw/axi_gpio_demo.c`
