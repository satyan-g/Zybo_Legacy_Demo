/*
 * qspi_boot_demo.c — QSPI flash boot demo for Zybo
 *
 * Distinctive LED pattern: 4-bit binary counter on LEDs.
 * Reads and prints the SLCR boot mode register to confirm boot source.
 * Prints boot banner to UART at 115200 baud.
 *
 * This is designed to look different from the SD boot demo so you
 * can visually confirm which boot source is active.
 */

#include "xgpio.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xparameters.h"

/* AXI GPIO channel for LEDs */
#define LED_CHANNEL 1

/* SLCR Boot Mode register (Zynq TRM Table 4-1) */
#define SLCR_BOOT_MODE_ADDR 0xF8000004

/* Boot mode field meanings (bits [3:0]) */
#define BOOT_MODE_JTAG  0x0
#define BOOT_MODE_QSPI  0x1
#define BOOT_MODE_NOR   0x2
#define BOOT_MODE_NAND  0x4
#define BOOT_MODE_SD    0x5

/* Delay loop count (~250ms at ~650 MHz Cortex-A9) */
#define COUNT_DELAY 2500000

static void delay(volatile int count)
{
    while (count-- > 0)
        ;
}

static const char *boot_mode_str(u32 mode)
{
    switch (mode & 0x7) {
    case BOOT_MODE_JTAG: return "JTAG";
    case BOOT_MODE_QSPI: return "QSPI";
    case BOOT_MODE_NOR:  return "NOR";
    case BOOT_MODE_NAND: return "NAND";
    case BOOT_MODE_SD:   return "SD";
    default:             return "UNKNOWN";
    }
}

int main(void)
{
    XGpio gpio;
    int status;
    u32 boot_mode_reg, boot_mode;
    u8 counter = 0;

    /* --- Boot banner --- */
    xil_printf("\r\n");
    xil_printf("############################################\r\n");
    xil_printf("#                                          #\r\n");
    xil_printf("#   14_qspi_boot — QSPI Flash Boot Demo   #\r\n");
    xil_printf("#   Board: Digilent Zybo (Original, Rev B) #\r\n");
    xil_printf("#                                          #\r\n");
    xil_printf("############################################\r\n");
    xil_printf("\r\n");

    /* --- Read and display boot mode --- */
    boot_mode_reg = Xil_In32(SLCR_BOOT_MODE_ADDR);
    boot_mode = boot_mode_reg & 0x7;

    xil_printf("BOOT_MODE register (0xF8000004) = 0x%08x\r\n", boot_mode_reg);
    xil_printf("Boot mode [2:0] = %d => %s\r\n", boot_mode, boot_mode_str(boot_mode));
    xil_printf("\r\n");

    if (boot_mode == BOOT_MODE_QSPI) {
        xil_printf("*** Booted from QSPI flash! ***\r\n");
    } else if (boot_mode == BOOT_MODE_JTAG) {
        xil_printf("*** Booted via JTAG (test mode) ***\r\n");
        xil_printf("    Flash to QSPI and set JP5 for autonomous boot.\r\n");
    } else {
        xil_printf("*** Boot source: %s ***\r\n", boot_mode_str(boot_mode));
    }
    xil_printf("\r\n");

    /* --- Initialize AXI GPIO for LEDs --- */
    status = XGpio_Initialize(&gpio, XPAR_AXI_GPIO_0_BASEADDR);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: XGpio_Initialize failed (%d)\r\n", status);
        return -1;
    }

    /* LEDs are all outputs (direction = 0) */
    XGpio_SetDataDirection(&gpio, LED_CHANNEL, 0x00);

    /* Startup flash: all LEDs on then off */
    XGpio_DiscreteWrite(&gpio, LED_CHANNEL, 0x0F);
    delay(COUNT_DELAY * 2);
    XGpio_DiscreteWrite(&gpio, LED_CHANNEL, 0x00);
    delay(COUNT_DELAY);

    xil_printf("Starting binary counter on LEDs...\r\n");
    xil_printf("Pattern: 0000 -> 0001 -> 0010 -> ... -> 1111 -> repeat\r\n\r\n");

    /* --- Main loop: binary counter on LEDs --- */
    while (1) {
        XGpio_DiscreteWrite(&gpio, LED_CHANNEL, counter & 0x0F);

        if ((counter & 0x0F) == 0) {
            xil_printf("LED counter cycle (count=%d)\r\n", counter);
        }

        delay(COUNT_DELAY);
        counter++;
    }

    return 0;
}
