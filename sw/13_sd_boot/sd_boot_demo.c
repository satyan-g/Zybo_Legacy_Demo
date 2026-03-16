/*
 * sd_boot_demo.c — SD Card Boot Demo for Original Zybo
 *
 * Knight Rider LED chaser pattern + UART messages confirming standalone boot.
 * Reads the boot mode register to verify SD card boot.
 *
 * Hardware: PS7 + AXI GPIO (4-bit LEDs)
 * UART: UART1 at 115200/8N1 (via USB-JTAG)
 */

#include "xparameters.h"
#include "xgpio.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "sleep.h"

/* AXI GPIO instance */
#define GPIO_DEVICE_ID  XPAR_AXI_GPIO_0_BASEADDR
#define LED_CHANNEL     1
#define NUM_LEDS        4

/* Zynq SLCR boot mode register */
#define SLCR_BOOT_MODE_ADDR  0xF800025C

/* Boot mode definitions */
#define BOOT_MODE_MASK       0x0000000F
#define BOOT_MODE_JTAG       0x0
#define BOOT_MODE_QSPI       0x1
#define BOOT_MODE_NOR        0x2
#define BOOT_MODE_NAND       0x4
#define BOOT_MODE_SD         0x5

static XGpio gpio;

static const char *boot_mode_str(u32 mode)
{
    switch (mode & BOOT_MODE_MASK) {
    case BOOT_MODE_JTAG: return "JTAG";
    case BOOT_MODE_QSPI: return "QSPI";
    case BOOT_MODE_NOR:  return "NOR";
    case BOOT_MODE_NAND: return "NAND";
    case BOOT_MODE_SD:   return "SD Card";
    default:             return "Unknown";
    }
}

static void print_banner(void)
{
    u32 boot_mode;

    xil_printf("\r\n");
    xil_printf("==========================================\r\n");
    xil_printf("  Zybo SD Card Boot Demo (13_sd_boot)\r\n");
    xil_printf("==========================================\r\n");
    xil_printf("\r\n");

    /* Read boot mode register */
    boot_mode = Xil_In32(SLCR_BOOT_MODE_ADDR);
    xil_printf("Boot mode register: 0x%08X\r\n", boot_mode);
    xil_printf("Boot source: %s\r\n", boot_mode_str(boot_mode));

    if ((boot_mode & BOOT_MODE_MASK) == BOOT_MODE_SD) {
        xil_printf("Booted from SD card!\r\n");
    } else {
        xil_printf("NOTE: Not booted from SD (probably JTAG).\r\n");
    }

    xil_printf("\r\n");
    xil_printf("Starting LED chaser pattern...\r\n");
    xil_printf("\r\n");
}

int main(void)
{
    int status;
    int pos;
    int direction; /* 1 = right, -1 = left */
    u32 led_val;
    u32 cycle_count = 0;

    /* Initialize GPIO */
    status = XGpio_Initialize(&gpio, GPIO_DEVICE_ID);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: GPIO init failed (status=%d)\r\n", status);
        return XST_FAILURE;
    }

    /* Set LEDs as output (direction 0 = output) */
    XGpio_SetDataDirection(&gpio, LED_CHANNEL, 0x0);

    /* All LEDs off */
    XGpio_DiscreteWrite(&gpio, LED_CHANNEL, 0x0);

    /* Print boot info */
    print_banner();

    /* Knight Rider chaser loop */
    pos = 0;
    direction = 1;

    while (1) {
        /* Light up current LED */
        led_val = (1 << pos);
        XGpio_DiscreteWrite(&gpio, LED_CHANNEL, led_val);

        /* Delay for visible effect */
        usleep(100000); /* 100 ms */

        /* Move to next position */
        pos += direction;

        /* Bounce at edges */
        if (pos >= NUM_LEDS - 1) {
            pos = NUM_LEDS - 1;
            direction = -1;
        } else if (pos <= 0) {
            pos = 0;
            direction = 1;
            cycle_count++;

            /* Print periodic status */
            if ((cycle_count % 10) == 0) {
                xil_printf("LED chaser: %d cycles completed\r\n", cycle_count);
            }
        }
    }

    return 0;
}
