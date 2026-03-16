# 07 — AXI Timer

An AXI Timer fires an interrupt every 500 ms, cycling through LED patterns.
Demonstrates timer peripheral setup and periodic ISR execution.

## Hardware Setup
- AXI Timer/Counter IP connected to Zynq PS via AXI interconnect.
- Timer interrupt routed to the GIC.
- LEDs directly driven or via AXI GPIO.

## Build and Run
```
./scripts/build_hw.sh 07_timer
./scripts/build_sw.sh 07_timer
./scripts/deploy.sh 07_timer
```

## What to Expect
- LEDs cycle through patterns every 500 ms.
- Serial console prints ISR count and LED pattern using `.` (off) and `*` (on).

## Source
- `sw/07_timer/timer_demo.c`
