# 07 — AXI Timer

An AXI Timer/Counter IP fires an interrupt every 500 ms. The ISR cycles
through four LED patterns (binary counter) and prints a status line.
Demonstrates precise periodic execution without busy-waiting.

**Teaches:** AXI Timer IP, timer interrupt setup, XTmrCtr driver,
period calculation (AXI clock frequency → timer load value).

## Build and Run
```
./scripts/build_hw.sh 07_timer
./scripts/build_sw.sh 07_timer
./scripts/deploy.sh 07_timer
```

## What to Expect
- LEDs cycle through patterns every 500 ms.
- Serial console prints ISR count and LED pattern with `.` (off) and `*` (on).

## Source
- `src/07_timer/sw/timer_demo.c`
