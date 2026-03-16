# 09 — AXI DMA Loopback

Sends data from PS memory through the PL via AXI DMA and reads it back.
Verifies data integrity across 4 rounds of different transfer sizes.

## Hardware Setup
- AXI DMA IP connected to Zynq PS via AXI interconnect and HP port.
- PL-side AXI Stream FIFO (or direct MM2S-to-S2MM loopback) for data return path.

## Build and Run
```
./scripts/build_hw.sh 09_dma
./scripts/build_sw.sh 09_dma
./scripts/deploy.sh 09_dma
```

## What to Expect
- Serial console prints each round's transfer size and pass/fail status.
- Uses polling mode (no interrupts).
- All 4 rounds should report data match.

## Source
- `sw/09_dma/dma_demo.c`
