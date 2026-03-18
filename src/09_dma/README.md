# 09 — AXI DMA Loopback

Moves data between two DDR buffers through the PL using AXI DMA. The
transfer path is: DDR (src) → DMA MM2S → AXI Stream Data FIFO → DMA S2MM
→ DDR (dst). Runs 4 rounds with increasing transfer sizes and verifies
byte-for-byte data integrity. Uses polling mode (no interrupts).

**Teaches:** AXI DMA IP, MM2S/S2MM channels, AXI Stream Data FIFO,
cache coherency (Xil_DCacheFlush), HP port addressing, polling vs interrupt.

## Build and Run
```
./scripts/build_hw.sh 09_dma
./scripts/build_sw.sh 09_dma
./scripts/deploy.sh 09_dma
```

## What to Expect
- Serial console prints each transfer size and PASS/FAIL.
- All 4 rounds should pass. Any failure indicates a wiring or addressing issue.

## Source
- `src/09_dma/sw/dma_demo.c`
