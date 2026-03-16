/*
 * xadc_demo.c — Read XADC on-chip sensors and external analog inputs
 * Displays temperature, VCCINT, VCCAUX, and Pmod JA analog readings on UART
 * LEDs show a bar graph of die temperature
 */

#include "xparameters.h"
#include "xsysmon.h"
#include "xgpio.h"
#include "xil_printf.h"
#include "xstatus.h"

/* XADC raw-to-physical conversion macros */
#define XADC_RAW_TO_TEMP(raw)    ((float)(raw) * 503.975f / 65536.0f - 273.15f)
#define XADC_RAW_TO_VOLT(raw)    ((float)(raw) * 3.0f / 65536.0f)

/* Temperature thresholds for LED bar (Celsius) */
#define TEMP_THRESH_1  35.0f   /* LED 0 on */
#define TEMP_THRESH_2  45.0f   /* LED 1 on */
#define TEMP_THRESH_3  55.0f   /* LED 2 on */
#define TEMP_THRESH_4  65.0f   /* LED 3 on */

/* Auxiliary channel numbers for Pmod JA */
#define XADC_AUX_CH6   6    /* JA1 */
#define XADC_AUX_CH14  14   /* JA2 */
#define XADC_AUX_CH7   7    /* JA3 */
#define XADC_AUX_CH15  15   /* JA4 */

/* LED channel */
#define GPIO_LED_CHANNEL 1

static XSysMon xadc;
static XGpio   gpio_leds;

static int init_xadc(void)
{
    XSysMon_Config *cfg;
    int status;

    cfg = XSysMon_LookupConfig(XPAR_XADC_WIZ_0_BASEADDR);
    if (cfg == NULL) {
        xil_printf("ERROR: XADC config lookup failed\r\n");
        return XST_FAILURE;
    }

    status = XSysMon_CfgInitialize(&xadc, cfg, cfg->BaseAddress);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: XADC init failed (status %d)\r\n", status);
        return XST_FAILURE;
    }

    /*
     * Self-test the XADC
     */
    status = XSysMon_SelfTest(&xadc);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: XADC self-test failed\r\n");
        return XST_FAILURE;
    }

    /*
     * Disable the Channel Sequencer before configuring it.
     */
    XSysMon_SetSequencerMode(&xadc, XSM_SEQ_MODE_SAFE);

    /*
     * Enable channels in the sequencer:
     *   - On-chip: temperature, VCCINT, VCCAUX
     *   - Auxiliary: VAUX6, VAUX7, VAUX14, VAUX15
     */
    status = XSysMon_SetSeqChEnables(&xadc,
        XSM_SEQ_CH_TEMP | XSM_SEQ_CH_VCCINT | XSM_SEQ_CH_VCCAUX |
        XSM_SEQ_CH_AUX06 | XSM_SEQ_CH_AUX07 |
        XSM_SEQ_CH_AUX14 | XSM_SEQ_CH_AUX15);
    if (status != XST_SUCCESS) {
        xil_printf("WARNING: Could not set sequencer channels\r\n");
    }

    /*
     * Set all enabled channels to unipolar mode (0 to +1V input range)
     */
    XSysMon_SetSeqInputMode(&xadc, 0x00000000);

    /*
     * Enable averaging of 64 samples for on-chip sensors
     */
    XSysMon_SetAvg(&xadc, XSM_AVG_64_SAMPLES);
    XSysMon_SetSeqAvgEnables(&xadc,
        XSM_SEQ_CH_TEMP | XSM_SEQ_CH_VCCINT | XSM_SEQ_CH_VCCAUX |
        XSM_SEQ_CH_AUX06 | XSM_SEQ_CH_AUX07 |
        XSM_SEQ_CH_AUX14 | XSM_SEQ_CH_AUX15);

    /*
     * Start the sequencer in continuous mode
     */
    XSysMon_SetSequencerMode(&xadc, XSM_SEQ_MODE_CONTINPASS);

    return XST_SUCCESS;
}

static int init_gpio(void)
{
    int status;

    status = XGpio_Initialize(&gpio_leds, XPAR_AXI_GPIO_0_BASEADDR);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: GPIO init failed\r\n");
        return XST_FAILURE;
    }

    /* Set all 4 LED bits as outputs (0 = output) */
    XGpio_SetDataDirection(&gpio_leds, GPIO_LED_CHANNEL, 0x0);

    /* Turn off all LEDs initially */
    XGpio_DiscreteWrite(&gpio_leds, GPIO_LED_CHANNEL, 0x0);

    return XST_SUCCESS;
}

/*
 * Print a fixed-point representation of a float using xil_printf
 * (xil_printf does not support %f)
 */
static void print_float(float val, int decimals)
{
    int integer_part;
    int frac_part;
    int scale = 1;

    for (int i = 0; i < decimals; i++)
        scale *= 10;

    if (val < 0.0f) {
        xil_printf("-");
        val = -val;
    }

    integer_part = (int)val;
    frac_part = (int)((val - (float)integer_part) * (float)scale + 0.5f);

    /* Handle rounding overflow */
    if (frac_part >= scale) {
        integer_part++;
        frac_part -= scale;
    }

    if (decimals == 2) {
        xil_printf("%d.%02d", integer_part, frac_part);
    } else if (decimals == 3) {
        xil_printf("%d.%03d", integer_part, frac_part);
    } else {
        xil_printf("%d.%d", integer_part, frac_part);
    }
}

/*
 * Update LED bar graph based on temperature
 */
static void update_led_bar(float temp_c)
{
    u32 led_val = 0;

    if (temp_c >= TEMP_THRESH_1) led_val |= 0x1;
    if (temp_c >= TEMP_THRESH_2) led_val |= 0x2;
    if (temp_c >= TEMP_THRESH_3) led_val |= 0x4;
    if (temp_c >= TEMP_THRESH_4) led_val |= 0x8;

    XGpio_DiscreteWrite(&gpio_leds, GPIO_LED_CHANNEL, led_val);
}

int main(void)
{
    u16 raw;
    float temp_c, vccint_v, vccaux_v;
    float vaux6_v, vaux7_v, vaux14_v, vaux15_v;
    int iteration = 0;

    xil_printf("\r\n============================================\r\n");
    xil_printf(" XADC Demo — Zybo (Original, Rev B)\r\n");
    xil_printf(" On-chip sensors + Pmod JA analog inputs\r\n");
    xil_printf("============================================\r\n\r\n");

    if (init_xadc() != XST_SUCCESS) {
        xil_printf("FATAL: XADC initialization failed\r\n");
        return -1;
    }
    xil_printf("XADC initialized OK\r\n");

    if (init_gpio() != XST_SUCCESS) {
        xil_printf("FATAL: GPIO initialization failed\r\n");
        return -1;
    }
    xil_printf("GPIO (LEDs) initialized OK\r\n\r\n");

    xil_printf("LED bar thresholds: >%dC >%dC >%dC >%dC\r\n",
               (int)TEMP_THRESH_1, (int)TEMP_THRESH_2,
               (int)TEMP_THRESH_3, (int)TEMP_THRESH_4);
    xil_printf("Reading sensors every ~1 second...\r\n\r\n");

    while (1) {
        /* Wait for end-of-sequence */
        while ((XSysMon_GetStatus(&xadc) & XSM_SR_EOS_MASK) == 0)
            ;

        /* ---- On-chip sensors ---- */

        /* Temperature */
        raw = XSysMon_GetAdcData(&xadc, XSM_CH_TEMP);
        temp_c = XADC_RAW_TO_TEMP(raw);

        /* VCCINT */
        raw = XSysMon_GetAdcData(&xadc, XSM_CH_VCCINT);
        vccint_v = XADC_RAW_TO_VOLT(raw);

        /* VCCAUX */
        raw = XSysMon_GetAdcData(&xadc, XSM_CH_VCCAUX);
        vccaux_v = XADC_RAW_TO_VOLT(raw);

        /* ---- Auxiliary channels (Pmod JA) ---- */

        raw = XSysMon_GetAdcData(&xadc, XSM_CH_AUX_MIN + XADC_AUX_CH6);
        vaux6_v = XADC_RAW_TO_VOLT(raw);

        raw = XSysMon_GetAdcData(&xadc, XSM_CH_AUX_MIN + XADC_AUX_CH14);
        vaux14_v = XADC_RAW_TO_VOLT(raw);

        raw = XSysMon_GetAdcData(&xadc, XSM_CH_AUX_MIN + XADC_AUX_CH7);
        vaux7_v = XADC_RAW_TO_VOLT(raw);

        raw = XSysMon_GetAdcData(&xadc, XSM_CH_AUX_MIN + XADC_AUX_CH15);
        vaux15_v = XADC_RAW_TO_VOLT(raw);

        /* ---- Display ---- */

        xil_printf("[%d] ", iteration++);

        xil_printf("Temp=");
        print_float(temp_c, 2);

        xil_printf("C  VCCINT=");
        print_float(vccint_v, 3);

        xil_printf("V  VCCAUX=");
        print_float(vccaux_v, 3);

        xil_printf("V\r\n");

        xil_printf("     JA1(Aux6)=");
        print_float(vaux6_v, 3);

        xil_printf("V  JA2(Aux14)=");
        print_float(vaux14_v, 3);

        xil_printf("V  JA3(Aux7)=");
        print_float(vaux7_v, 3);

        xil_printf("V  JA4(Aux15)=");
        print_float(vaux15_v, 3);

        xil_printf("V\r\n\r\n");

        /* Update LED bar based on temperature */
        update_led_bar(temp_c);

        /* Delay ~1 second */
        for (volatile int d = 0; d < 5000000; d++)
            ;
    }

    return 0;
}
