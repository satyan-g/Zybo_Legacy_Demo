# 06 — Interrupt-Driven GPIO

Replaces polling with hardware interrupts. Button presses assert an interrupt
line from the AXI GPIO IP to the Zynq GIC (Generic Interrupt Controller).
The ISR reads which button triggered, toggles its LED, and clears the interrupt.
The main loop is idle — all work happens in the ISR.

**Teaches:** Zynq GIC setup (XScuGic), AXI GPIO interrupt output,
fabric interrupt IDs (XPAR_FABRIC_*_INTR + 32), ISR registration.

## Build and Run
```
./scripts/build_hw.sh 06_interrupts
./scripts/build_sw.sh 06_interrupts
./scripts/deploy.sh 06_interrupts
```

## What to Expect
- Press a button → its LED toggles immediately.
- Serial console prints which button was pressed and the new LED state.

## Source
- `src/06_interrupts/sw/interrupt_demo.c`
