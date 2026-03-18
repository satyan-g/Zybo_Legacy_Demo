/*
 * dma_demo.c — AXI DMA loopback transfer demo (polling mode)
 *
 * Transfers data from one DDR region through the PL AXI Stream Data FIFO
 * and back to another DDR region using the AXI DMA engine.
 *
 * Flow: DDR (src) → DMA MM2S → FIFO → DMA S2MM → DDR (dst)
 */

#include "xaxidma.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xparameters.h"

#define DMA_DEV_ID        XPAR_AXI_DMA_0_BASEADDR
#define NUM_TRANSFERS     4

/* Buffers in DDR — cache-line aligned */
#define TX_BUFFER_BASE    0x01000000
#define RX_BUFFER_BASE    0x01100000

static XAxiDma dma_inst;

static int setup_dma(void)
{
    XAxiDma_Config *cfg;
    int status;

    cfg = XAxiDma_LookupConfig(DMA_DEV_ID);
    if (!cfg) {
        xil_printf("ERROR: DMA config not found\r\n");
        return XST_FAILURE;
    }

    status = XAxiDma_CfgInitialize(&dma_inst, cfg);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: DMA init failed (%d)\r\n", status);
        return XST_FAILURE;
    }

    if (XAxiDma_HasSg(&dma_inst)) {
        xil_printf("ERROR: DMA in SG mode (expected simple)\r\n");
        return XST_FAILURE;
    }

    /* Disable all interrupts — pure polling */
    XAxiDma_IntrDisable(&dma_inst, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrDisable(&dma_inst, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    return XST_SUCCESS;
}

static int run_transfer(int round, u8 start_val, u32 length)
{
    u8 *tx_buf = (u8 *)TX_BUFFER_BASE;
    u8 *rx_buf = (u8 *)RX_BUFFER_BASE;
    u32 i;
    int status;

    /* Fill source, clear dest */
    for (i = 0; i < length; i++) {
        tx_buf[i] = (u8)(start_val + (i & 0xFF));
        rx_buf[i] = 0;
    }

    /* Flush TX to DDR, invalidate RX */
    Xil_DCacheFlushRange((UINTPTR)tx_buf, length);
    Xil_DCacheInvalidateRange((UINTPTR)rx_buf, length);

    /* Start S2MM (receive) first, then MM2S (transmit) */
    status = XAxiDma_SimpleTransfer(&dma_inst, (UINTPTR)rx_buf, length,
                                    XAXIDMA_DEVICE_TO_DMA);
    if (status != XST_SUCCESS) {
        xil_printf("  ERROR: S2MM start failed (%d)\r\n", status);
        return XST_FAILURE;
    }

    status = XAxiDma_SimpleTransfer(&dma_inst, (UINTPTR)tx_buf, length,
                                    XAXIDMA_DMA_TO_DEVICE);
    if (status != XST_SUCCESS) {
        xil_printf("  ERROR: MM2S start failed (%d)\r\n", status);
        return XST_FAILURE;
    }

    /* Poll for MM2S completion */
    xil_printf("  Waiting MM2S...");
    int timeout = 50000000;
    while (XAxiDma_Busy(&dma_inst, XAXIDMA_DMA_TO_DEVICE) && timeout > 0)
        timeout--;
    if (timeout <= 0) {
        xil_printf(" TIMEOUT\r\n");
        return XST_FAILURE;
    }
    xil_printf(" done. ");

    /* Poll for S2MM completion */
    xil_printf("S2MM...");
    timeout = 50000000;
    while (XAxiDma_Busy(&dma_inst, XAXIDMA_DEVICE_TO_DMA) && timeout > 0)
        timeout--;
    if (timeout <= 0) {
        xil_printf(" TIMEOUT\r\n");
        return XST_FAILURE;
    }
    xil_printf(" done.\r\n");

    /* Invalidate RX cache — DMA wrote to DDR behind cache */
    Xil_DCacheInvalidateRange((UINTPTR)rx_buf, length);

    /* Verify */
    int errors = 0;
    for (i = 0; i < length; i++) {
        if (rx_buf[i] != tx_buf[i]) {
            if (errors < 4) {
                xil_printf("  MISMATCH [%d]: exp=0x%02x got=0x%02x\r\n",
                           i, tx_buf[i], rx_buf[i]);
            }
            errors++;
        }
    }

    if (errors > 0) {
        xil_printf("  FAIL: %d/%d bytes mismatched\r\n", errors, length);
        return XST_FAILURE;
    }

    xil_printf("  PASS: %d bytes verified\r\n", length);
    return XST_SUCCESS;
}

int main(void)
{
    int status;
    int pass = 0, fail = 0;

    xil_printf("\r\n============================================\r\n");
    xil_printf(" 09_dma: AXI DMA Loopback (Polling Mode)\r\n");
    xil_printf(" Board: Digilent Zybo (Original, Rev B)\r\n");
    xil_printf("============================================\r\n\r\n");

    status = setup_dma();
    if (status != XST_SUCCESS) return -1;
    xil_printf("DMA initialized (simple, no SG, polling)\r\n\r\n");

    u32 lengths[] = { 64, 256, 1024, 4096 };
    u8 patterns[] = { 0x10, 0xAA, 0x55, 0x01 };

    for (int i = 0; i < NUM_TRANSFERS; i++) {
        xil_printf("Round %d: %d bytes, pattern=0x%02x\r\n",
                   i + 1, lengths[i], patterns[i]);
        status = run_transfer(i + 1, patterns[i], lengths[i]);
        if (status == XST_SUCCESS) pass++; else fail++;
    }

    xil_printf("\r\nResult: %d/%d passed\r\n", pass, NUM_TRANSFERS);
    if (fail == 0)
        xil_printf("*** ALL TESTS PASSED ***\r\n");
    else
        xil_printf("*** %d TESTS FAILED ***\r\n", fail);

    while (1) {}
    return 0;
}
