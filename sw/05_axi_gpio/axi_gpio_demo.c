/*
 * axi_gpio_demo.c — AXI GPIO demo for Zybo
 *
 * Reads switches (4) and buttons (4) via AXI GPIO channel 2,
 * writes LED patterns via AXI GPIO channel 1.
 * Prints status to UART at 115200 baud.
 *
 * AXI GPIO layout:
 *   Channel 1: 4-bit output — LEDs [3:0]
 *   Channel 2: 8-bit input  — SW[3:0] | BTN[7:4]
 */

#include "xgpio.h"
#include "xil_printf.h"
#include "xparameters.h"

/* AXI GPIO channels */
#define LED_CHANNEL   1
#define INPUT_CHANNEL 2

/* Delay loop count (~200ms at ~666 MHz Cortex-A9) */
#define LOOP_DELAY 2000000

static void delay(volatile int count)
{
    while (count-- > 0)
        ;
}

int main(void)
{
    XGpio gpio;
    int status;
    u8 sw_btn, sw, btn, led_val;
    u8 prev_sw_btn = 0xFF; /* force first print */

    xil_printf("\r\n============================================\r\n");
    xil_printf(" 05_axi_gpio — AXI GPIO Demo\r\n");
    xil_printf(" Board: Digilent Zybo (Original, Rev B)\r\n");
    xil_printf("============================================\r\n\r\n");

    /* Initialize AXI GPIO */
    status = XGpio_Initialize(&gpio, XPAR_AXI_GPIO_0_BASEADDR);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: XGpio_Initialize failed (%d)\r\n", status);
        return -1;
    }

    /* Channel 1: LEDs — all outputs (direction = 0) */
    XGpio_SetDataDirection(&gpio, LED_CHANNEL, 0x00);

    /* Channel 2: SW+BTN — all inputs (direction = 1) */
    XGpio_SetDataDirection(&gpio, INPUT_CHANNEL, 0xFF);

    xil_printf("GPIO initialized. Reading switches/buttons...\r\n\r\n");

    /* Turn on all LEDs briefly as a startup indicator */
    XGpio_DiscreteWrite(&gpio, LED_CHANNEL, 0x0F);
    delay(LOOP_DELAY * 3);
    XGpio_DiscreteWrite(&gpio, LED_CHANNEL, 0x00);

    while (1) {
        /* Read switches [3:0] and buttons [7:4] from channel 2 */
        sw_btn = (u8)XGpio_DiscreteRead(&gpio, INPUT_CHANNEL);
        sw  = sw_btn & 0x0F;        /* lower 4 bits = switches */
        btn = (sw_btn >> 4) & 0x0F;  /* upper 4 bits = buttons  */

        /* Combine: OR switches and buttons to drive LEDs */
        led_val = sw | btn;
        XGpio_DiscreteWrite(&gpio, LED_CHANNEL, led_val);

        /* Print only when input changes */
        if (sw_btn != prev_sw_btn) {
            xil_printf("SW=%x BTN=%x -> LED=%x\r\n", sw, btn, led_val);
            prev_sw_btn = sw_btn;
        }

        delay(LOOP_DELAY);
    }

    return 0;
}
