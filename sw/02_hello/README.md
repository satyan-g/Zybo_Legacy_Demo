# 02 — PS UART Hello World

Minimal bare-metal program that prints "Hello, World!" over the PS UART.
No PL logic is used; the ARM core runs standalone.

## Hardware Setup
- Zynq PS only — no block design peripherals beyond default UART1 (MIO 48/49).

## Build and Run
```
./scripts/build_hw.sh 02_hello
./scripts/build_sw.sh 02_hello
./scripts/deploy.sh 02_hello
```

## What to Expect
- Serial console (115200 8N1) prints `Hello, World from Zybo!` (or similar).
- No LED activity — this is a UART-only demo.

## Source
- `sw/02_hello/hello.c`
