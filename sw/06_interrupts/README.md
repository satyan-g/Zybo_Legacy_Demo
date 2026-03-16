# 06 — Interrupt-Driven GPIO

Button presses trigger hardware interrupts that toggle the corresponding LED.
Demonstrates GIC setup, interrupt registration, and ISR handling on Zynq.

## Hardware Setup
- AXI GPIO with interrupt output connected to the Zynq PS GIC (via `ip2intc_irpt`).
- Buttons on one channel, LEDs on another.

## Build and Run
```
./scripts/build_hw.sh 06_interrupts
./scripts/build_sw.sh 06_interrupts
./scripts/deploy.sh 06_interrupts
```

## What to Expect
- Each button press toggles its corresponding LED (BTN0 -> LD0, etc.).
- Serial console prints which button was pressed and the new LED state.

## Source
- `sw/06_interrupts/interrupt_demo.c`
