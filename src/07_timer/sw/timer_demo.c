/*
 * timer_demo.c — AXI Timer interrupt demo for Original Zybo
 *
 * Uses AXI Timer in auto-reload mode to generate interrupts every 500ms.
 * Each interrupt toggles the LED pattern. Timer count is printed periodically
 * from the main loop.
 *
 * Hardware: Zynq PS7 + AXI Timer + AXI GPIO (4 LEDs)
 * FCLK_CLK0 = 100 MHz → 500ms = 50,000,000 timer counts
 */

#include "xparameters.h"
#include "xtmrctr.h"
#include "xgpio.h"
#include "xscugic.h"
#include "xil_exception.h"
#include "xil_printf.h"

/* ---- Device IDs (from xparameters.h) ---- */
#define TIMER_DEVICE_ID     XPAR_AXI_TIMER_0_BASEADDR
#define GPIO_DEVICE_ID      XPAR_AXI_GPIO_0_BASEADDR
#define INTC_DEVICE_ID      XPAR_XSCUGIC_0_BASEADDR
#define TIMER_IRPT_INTR     (XPAR_FABRIC_AXI_TIMER_0_INTR + 32)  /* SPI→GIC: +32 */

/* ---- Timer config ---- */
#define TIMER_CNT_0         0           /* Use timer/counter 0 */
#define TIMER_FREQ_HZ       100000000   /* FCLK_CLK0 = 100 MHz */
#define TOGGLE_INTERVAL_MS  500
#define RESET_VALUE          (TIMER_FREQ_HZ / (1000 / TOGGLE_INTERVAL_MS))
/* 100MHz * 0.5s = 50,000,000 counts */

/* ---- GPIO config ---- */
#define LED_CHANNEL         1           /* AXI GPIO channel 1 */

/* ---- Global instances ---- */
static XTmrCtr timer_inst;
static XGpio   gpio_inst;
static XScuGic intc_inst;

/* ---- Interrupt state ---- */
static volatile u32 led_pattern = 0x01;     /* Start with LED0 on */
static volatile u32 timer_isr_count = 0;

/* ---- LED patterns to cycle through ---- */
static const u32 patterns[] = {
    0x01,   /* LED0 */
    0x02,   /* LED1 */
    0x04,   /* LED2 */
    0x08,   /* LED3 */
    0x0F,   /* All on */
    0x05,   /* LED0 + LED2 */
    0x0A,   /* LED1 + LED3 */
    0x00,   /* All off */
};
#define NUM_PATTERNS (sizeof(patterns) / sizeof(patterns[0]))

/*
 * Timer interrupt handler — called every 500ms
 */
static void timer_isr(void *callback_ref, u8 timer_num)
{
    (void)callback_ref;
    (void)timer_num;

    timer_isr_count++;

    /* Cycle through LED patterns */
    u32 idx = timer_isr_count % NUM_PATTERNS;
    led_pattern = patterns[idx];

    /* Write to GPIO LEDs */
    XGpio_DiscreteWrite(&gpio_inst, LED_CHANNEL, led_pattern);
}

/*
 * Set up the GIC and connect the timer interrupt
 */
static int setup_interrupt_system(void)
{
    int status;
    XScuGic_Config *intc_cfg;

    /* Initialize GIC */
    intc_cfg = XScuGic_LookupConfig(INTC_DEVICE_ID);
    if (!intc_cfg) {
        xil_printf("ERROR: GIC config lookup failed\r\n");
        return XST_FAILURE;
    }

    status = XScuGic_CfgInitialize(&intc_inst, intc_cfg,
                                    intc_cfg->CpuBaseAddress);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: GIC init failed\r\n");
        return XST_FAILURE;
    }

    /* Set timer interrupt priority and trigger type */
    XScuGic_SetPriorityTriggerType(&intc_inst, TIMER_IRPT_INTR,
                                    0xA0, 0x3);

    /* Connect timer interrupt handler to GIC */
    status = XScuGic_Connect(&intc_inst, TIMER_IRPT_INTR,
                              (Xil_ExceptionHandler)XTmrCtr_InterruptHandler,
                              &timer_inst);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: GIC connect failed\r\n");
        return XST_FAILURE;
    }

    /* Enable timer interrupt in GIC */
    XScuGic_Enable(&intc_inst, TIMER_IRPT_INTR);

    /* Connect GIC to ARM exception system */
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
                                  (Xil_ExceptionHandler)XScuGic_InterruptHandler,
                                  &intc_inst);
    Xil_ExceptionEnable();

    return XST_SUCCESS;
}

int main(void)
{
    int status;
    u32 last_count = 0;

    xil_printf("\r\n============================================\r\n");
    xil_printf(" 07_timer: AXI Timer Interrupt Demo\r\n");
    xil_printf(" Board: Digilent Zybo (Original, Rev B)\r\n");
    xil_printf("============================================\r\n\r\n");

    /* ---- Initialize AXI GPIO ---- */
    xil_printf("Initializing AXI GPIO...\r\n");
    status = XGpio_Initialize(&gpio_inst, GPIO_DEVICE_ID);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: GPIO init failed\r\n");
        return XST_FAILURE;
    }

    /* Set LED channel as output (0 = output for each bit) */
    XGpio_SetDataDirection(&gpio_inst, LED_CHANNEL, 0x00);

    /* Turn on first LED to show we're alive */
    XGpio_DiscreteWrite(&gpio_inst, LED_CHANNEL, 0x01);
    xil_printf("GPIO ready — LED0 on\r\n");

    /* ---- Initialize AXI Timer ---- */
    xil_printf("Initializing AXI Timer...\r\n");
    status = XTmrCtr_Initialize(&timer_inst, TIMER_DEVICE_ID);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: Timer init failed\r\n");
        return XST_FAILURE;
    }

    /* Self-test */
    status = XTmrCtr_SelfTest(&timer_inst, TIMER_CNT_0);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: Timer self-test failed\r\n");
        return XST_FAILURE;
    }
    xil_printf("Timer self-test passed\r\n");

    /* Set up the timer interrupt handler callback */
    XTmrCtr_SetHandler(&timer_inst, timer_isr, &timer_inst);

    /* Configure timer: auto-reload, count down, interrupt enabled */
    XTmrCtr_SetOptions(&timer_inst, TIMER_CNT_0,
                        XTC_INT_MODE_OPTION |
                        XTC_AUTO_RELOAD_OPTION |
                        XTC_DOWN_COUNT_OPTION);

    /* Set the reset/reload value (counts down from this to 0) */
    XTmrCtr_SetResetValue(&timer_inst, TIMER_CNT_0, RESET_VALUE);

    xil_printf("Timer configured: %d ms interval (%d counts)\r\n",
               TOGGLE_INTERVAL_MS, RESET_VALUE);

    /* ---- Set up interrupt system ---- */
    xil_printf("Setting up interrupts...\r\n");
    status = setup_interrupt_system();
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: Interrupt setup failed\r\n");
        return XST_FAILURE;
    }
    xil_printf("Interrupts enabled\r\n");

    /* ---- Start the timer ---- */
    xil_printf("Starting timer...\r\n\r\n");
    XTmrCtr_Start(&timer_inst, TIMER_CNT_0);

    xil_printf("LEDs toggling every %d ms via timer interrupt\r\n", TOGGLE_INTERVAL_MS);
    xil_printf("Printing interrupt count every ~2 seconds...\r\n\r\n");

    /* ---- Main loop: periodically report timer ISR count ---- */
    while (1) {
        /* Wait until ISR count changes (event-driven, no busy-wait guessing) */
        while (timer_isr_count == last_count) {}

        u32 cur_count = timer_isr_count;
        u32 pat = led_pattern & 0xF;
        xil_printf("ISR #%d  %c%c%c%c\r\n", cur_count,
                   (pat & 0x8) ? '*' : '.',
                   (pat & 0x4) ? '*' : '.',
                   (pat & 0x2) ? '*' : '.',
                   (pat & 0x1) ? '*' : '.');
        last_count = cur_count;
    }

    return 0;
}
