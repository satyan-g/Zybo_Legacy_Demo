/*
 * interrupt_demo.c — Interrupt-driven GPIO demo for Zynq
 *
 * Button presses generate interrupts that toggle corresponding LEDs.
 * BTN0 toggles LED0, BTN1 toggles LED1, etc.
 *
 * Hardware: AXI GPIO dual-channel
 *   Ch1 = 4-bit output (LEDs)
 *   Ch2 = 4-bit input  (buttons, interrupt enabled)
 *   ip2intc_irpt → PS IRQ_F2P[0]
 */

#include "xparameters.h"
#include "xgpio.h"
#include "xscugic.h"
#include "xil_exception.h"
#include "xil_printf.h"

/* Channel definitions */
#define LED_CHANNEL   1
#define BTN_CHANNEL   2

/* GPIO and interrupt IDs from xparameters.h */
#define GPIO_DEVICE_ID    XPAR_AXI_GPIO_0_BASEADDR
#define INTC_DEVICE_ID    XPAR_XSCUGIC_0_BASEADDR
#define GPIO_INTERRUPT_ID (XPAR_FABRIC_AXI_GPIO_0_INTR + 32)  /* SPI→GIC: +32 */

/* Instances */
static XGpio Gpio;
static XScuGic Intc;

/* Current LED state (toggled in ISR) */
static volatile u32 LedState = 0;

/* Interrupt count for status reporting */
static volatile u32 IntrCount = 0;

/*
 * GPIO interrupt handler — called when any button changes state.
 * Reads which buttons are pressed, toggles corresponding LEDs.
 */
static void GpioIntrHandler(void *CallbackRef)
{
    XGpio *GpioPtr = (XGpio *)CallbackRef;
    u32 buttons;

    /* Disable GPIO interrupts while handling */
    XGpio_InterruptDisable(GpioPtr, XGPIO_IR_CH2_MASK);

    /* Check this is a channel 2 (buttons) interrupt */
    if ((XGpio_InterruptGetStatus(GpioPtr) & XGPIO_IR_CH2_MASK) == 0) {
        /* Not our interrupt, re-enable and return */
        XGpio_InterruptEnable(GpioPtr, XGPIO_IR_CH2_MASK);
        return;
    }

    /* Read button state */
    buttons = XGpio_DiscreteRead(GpioPtr, BTN_CHANNEL);

    /* Toggle LEDs for each pressed button */
    if (buttons != 0) {
        LedState ^= buttons;
        XGpio_DiscreteWrite(GpioPtr, LED_CHANNEL, LedState);
        IntrCount++;

        xil_printf("IRQ #%d: buttons=0x%X -> LEDs=0x%X\r\n",
                    IntrCount, buttons, LedState);
    }

    /* Clear the interrupt and re-enable */
    XGpio_InterruptClear(GpioPtr, XGPIO_IR_CH2_MASK);
    XGpio_InterruptEnable(GpioPtr, XGPIO_IR_CH2_MASK);
}

/*
 * Set up the GIC (Generic Interrupt Controller) and connect GPIO interrupt.
 * Returns XST_SUCCESS or XST_FAILURE.
 */
static int SetupInterrupts(void)
{
    int status;
    XScuGic_Config *IntcConfig;

    /* Initialize GIC */
    IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
    if (IntcConfig == NULL) {
        xil_printf("ERROR: GIC config lookup failed\r\n");
        return XST_FAILURE;
    }

    status = XScuGic_CfgInitialize(&Intc, IntcConfig,
                                     IntcConfig->CpuBaseAddress);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: GIC init failed (%d)\r\n", status);
        return XST_FAILURE;
    }

    /* Set priority and trigger type for GPIO interrupt */
    XScuGic_SetPriorityTriggerType(&Intc, GPIO_INTERRUPT_ID, 0xA0, 0x3);

    /* Connect GPIO interrupt handler */
    status = XScuGic_Connect(&Intc, GPIO_INTERRUPT_ID,
                              (Xil_ExceptionHandler)GpioIntrHandler,
                              (void *)&Gpio);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: GIC connect failed (%d)\r\n", status);
        return XST_FAILURE;
    }

    /* Enable GPIO interrupt in GIC */
    XScuGic_Enable(&Intc, GPIO_INTERRUPT_ID);

    /* Connect GIC to ARM exception system */
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
                                  (Xil_ExceptionHandler)XScuGic_InterruptHandler,
                                  &Intc);
    Xil_ExceptionEnable();

    return XST_SUCCESS;
}

int main(void)
{
    int status;

    xil_printf("\r\n============================================\r\n");
    xil_printf(" 06_interrupts: GPIO Interrupt Demo\r\n");
    xil_printf(" Board: Digilent Zybo (Original, Rev B)\r\n");
    xil_printf("============================================\r\n\r\n");

    /* Initialize GPIO */
    status = XGpio_Initialize(&Gpio, GPIO_DEVICE_ID);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: GPIO init failed (%d)\r\n", status);
        return XST_FAILURE;
    }

    /* Set directions: ch1 = output (LEDs), ch2 = input (buttons) */
    XGpio_SetDataDirection(&Gpio, LED_CHANNEL, 0x0);   /* all output */
    XGpio_SetDataDirection(&Gpio, BTN_CHANNEL, 0xF);   /* all input  */

    /* Start with all LEDs off */
    XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, 0x0);

    /* Enable GPIO interrupts on channel 2 (buttons) */
    XGpio_InterruptEnable(&Gpio, XGPIO_IR_CH2_MASK);
    XGpio_InterruptGlobalEnable(&Gpio);

    /* Set up GIC and connect handler */
    status = SetupInterrupts();
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: Interrupt setup failed\r\n");
        return XST_FAILURE;
    }

    xil_printf("Interrupts enabled. Press BTN0-BTN3 to toggle LEDs.\r\n");
    xil_printf("Waiting for button presses...\r\n\r\n");

    /* Main loop — interrupts do the real work */
    u32 last_count = 0;
    while (1) {
        /* Periodically print status if new interrupts occurred */
        if (IntrCount != last_count) {
            last_count = IntrCount;
        }

        /* Simple delay (~1 second at ~667 MHz) */
        for (volatile int d = 0; d < 10000000; d++);
    }

    return 0;
}
