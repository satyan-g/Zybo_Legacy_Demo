/*
 * hello.c — First bare-metal program on Zynq ARM core
 * Prints to UART1 at 115200 baud via USB serial console
 */

#include "xil_printf.h"

int main()
{
    xil_printf("Hello World from Zybo Zynq ARM!\r\n");
    xil_printf("Board: Digilent Zybo (Original, Rev B)\r\n");
    xil_printf("FPGA Part: xc7z010clg400-1\r\n\r\n");

    int count = 0;
    while (1) {
        xil_printf("Count: %d\r\n", count++);
        for (volatile int d = 0; d < 5000000; d++);
    }

    return 0;
}
