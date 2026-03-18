# 02 — PS UART Hello World

First bare-metal program running on the Zynq ARM Cortex-A9. The Vitis BSP
initializes the PS (clocks, DDR, UART1 on MIO 48/49) before main() runs.
The app prints a banner then counts forever, demonstrating that the ARM
core is alive and the serial link works.

**Teaches:** Zynq PS bring-up, Vitis BSP/platform, xil_printf over UART.

## Hardware Setup
- PS only — no PL bitstream required. UART via USB-JTAG at 115200 8N1.

## Build and Run
```
./scripts/build_hw.sh 02_hello
./scripts/build_sw.sh 02_hello
./scripts/deploy.sh 02_hello
```

## What to Expect
```
Hello World from Zybo Zynq ARM!
Board: Digilent Zybo (Original, Rev B)
FPGA Part: xc7z010clg400-1

Count: 0
Count: 1
...
```

## Source
- `src/02_hello/sw/hello.c`
