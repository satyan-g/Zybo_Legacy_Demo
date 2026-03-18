/*
 * custom_ip_demo.c — Bare-metal demo for custom AXI4-Lite slave peripheral
 *
 * Register map at base 0x43C00000:
 *   Reg0 (0x00): LED output     (R/W) — write LEDs[3:0]
 *   Reg1 (0x04): Switch input   (R)   — read switches[3:0]
 *   Reg2 (0x08): Scratch        (R/W) — general-purpose read/write
 *   Reg3 (0x0C): Counter        (R)   — free-running 32-bit counter
 */

#include "xil_printf.h"
#include "xil_io.h"
#include "sleep.h"

#define CUSTOM_IP_BASE  0x43C00000

#define REG_LED         (CUSTOM_IP_BASE + 0x00)
#define REG_SWITCH      (CUSTOM_IP_BASE + 0x04)
#define REG_SCRATCH     (CUSTOM_IP_BASE + 0x08)
#define REG_COUNTER     (CUSTOM_IP_BASE + 0x0C)

int main(void)
{
    u32 sw_val, scratch_rd, ctr1, ctr2;
    int i;

    xil_printf("\r\n============================================\r\n");
    xil_printf(" 08_custom_ip: Custom AXI4-Lite Slave Demo\r\n");
    xil_printf("============================================\r\n\r\n");

    /* ---- Scratch register test ---- */
    xil_printf("--- Scratch Register Test ---\r\n");
    Xil_Out32(REG_SCRATCH, 0xDEADBEEF);
    scratch_rd = Xil_In32(REG_SCRATCH);
    xil_printf("  Wrote 0xDEADBEEF, Read back: 0x%08X", scratch_rd);
    if (scratch_rd == 0xDEADBEEF)
        xil_printf(" [PASS]\r\n");
    else
        xil_printf(" [FAIL]\r\n");

    Xil_Out32(REG_SCRATCH, 0x12345678);
    scratch_rd = Xil_In32(REG_SCRATCH);
    xil_printf("  Wrote 0x12345678, Read back: 0x%08X", scratch_rd);
    if (scratch_rd == 0x12345678)
        xil_printf(" [PASS]\r\n");
    else
        xil_printf(" [FAIL]\r\n");

    Xil_Out32(REG_SCRATCH, 0x00000000);
    scratch_rd = Xil_In32(REG_SCRATCH);
    xil_printf("  Wrote 0x00000000, Read back: 0x%08X", scratch_rd);
    if (scratch_rd == 0x00000000)
        xil_printf(" [PASS]\r\n");
    else
        xil_printf(" [FAIL]\r\n");

    /* ---- Counter register test ---- */
    xil_printf("\r\n--- Counter Register Test ---\r\n");
    ctr1 = Xil_In32(REG_COUNTER);
    usleep(1000);  /* wait ~1ms */
    ctr2 = Xil_In32(REG_COUNTER);
    xil_printf("  Counter read 1: 0x%08X\r\n", ctr1);
    xil_printf("  Counter read 2: 0x%08X\r\n", ctr2);
    xil_printf("  Delta:          %u ticks", ctr2 - ctr1);
    if (ctr2 != ctr1)
        xil_printf(" [PASS - counter is running]\r\n");
    else
        xil_printf(" [FAIL - counter stuck]\r\n");

    /* ---- LED walking pattern ---- */
    xil_printf("\r\n--- LED Walking Pattern ---\r\n");
    for (i = 0; i < 3; i++) {
        Xil_Out32(REG_LED, 0x1);
        xil_printf("  LEDs = 0001\r\n");
        usleep(200000);

        Xil_Out32(REG_LED, 0x2);
        xil_printf("  LEDs = 0010\r\n");
        usleep(200000);

        Xil_Out32(REG_LED, 0x4);
        xil_printf("  LEDs = 0100\r\n");
        usleep(200000);

        Xil_Out32(REG_LED, 0x8);
        xil_printf("  LEDs = 1000\r\n");
        usleep(200000);
    }
    Xil_Out32(REG_LED, 0x0);

    /* ---- Continuous switch mirror loop ---- */
    xil_printf("\r\n--- Switch Mirror Mode (LEDs = switches) ---\r\n");
    xil_printf("Toggle switches to control LEDs. Running for 30 seconds...\r\n\r\n");

    u32 prev_sw = 0xFF;  /* force first print */
    for (i = 0; i < 300; i++) {
        sw_val = Xil_In32(REG_SWITCH) & 0xF;

        /* Update LEDs to match switches */
        Xil_Out32(REG_LED, sw_val);

        /* Print only when switch state changes */
        if (sw_val != prev_sw) {
            ctr1 = Xil_In32(REG_COUNTER);
            xil_printf("  SW=0x%X  LED=0x%X  Counter=0x%08X\r\n",
                        sw_val, sw_val, ctr1);
            prev_sw = sw_val;
        }

        usleep(100000);  /* 100ms poll */
    }

    /* All LEDs on as final state */
    Xil_Out32(REG_LED, 0xF);
    xil_printf("\r\n--- Demo complete! All LEDs ON. ---\r\n");

    return 0;
}
