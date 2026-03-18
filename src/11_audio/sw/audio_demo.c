/*
 * audio_demo.c -- Configure SSM2603 codec via I2C for 48 kHz I2S playback
 *
 * The PL-side i2s_tone_gen module handles BCLK/LRCK/data generation.
 * This software configures the codec registers over I2C so the DAC is
 * active and routed to the headphone output.
 *
 * SSM2603 I2C address: 0x1A (7-bit)
 * Register format: 7-bit address + 9-bit data (sent as two bytes)
 */

#include "xil_printf.h"
#include "xiic.h"
#include "xparameters.h"
#include "sleep.h"

/* SSM2603 I2C address */
#define SSM2603_ADDR  0x1A

/* SSM2603 register addresses */
#define REG_LEFT_ADC_VOL      0x00
#define REG_RIGHT_ADC_VOL     0x01
#define REG_LEFT_DAC_VOL      0x02
#define REG_RIGHT_DAC_VOL     0x03
#define REG_ANALOG_PATH       0x04
#define REG_DIGITAL_PATH      0x05
#define REG_POWER_MGMT        0x06
#define REG_DIGITAL_IF        0x07
#define REG_SAMPLE_RATE       0x08
#define REG_ACTIVE            0x09
#define REG_RESET             0x0F

/* AXI IIC instance */
static XIic Iic;

/*
 * Write a 9-bit value to an SSM2603 register.
 * Wire format: byte0 = (reg_addr << 1) | data[8], byte1 = data[7:0]
 */
static int ssm2603_write(u8 reg, u16 data)
{
    u8 buf[2];
    int status;

    buf[0] = (reg << 1) | ((data >> 8) & 0x01);
    buf[1] = data & 0xFF;

    status = XIic_Send(Iic.BaseAddress, SSM2603_ADDR, buf, 2, XIIC_STOP);
    if (status != 2) {
        xil_printf("  I2C write FAILED: reg 0x%02x, sent %d bytes\r\n", reg, status);
        return -1;
    }
    return 0;
}

/*
 * Configure SSM2603 for 48 kHz I2S playback through headphone output.
 * Follows the recommended power-up sequence from the datasheet.
 */
static int ssm2603_init(void)
{
    int rc = 0;

    xil_printf(">>> Configuring SSM2603 codec...\r\n");

    /* 1. Reset the codec */
    xil_printf("  Reset...\r\n");
    rc |= ssm2603_write(REG_RESET, 0x000);
    usleep(50000); /* 50 ms settle */

    /* 2. Power management: power on everything except mic input and oscillator
     *    Bit map: PWROFF=0, CLK=0, OSC=1, OUT=0, DAC=0, ADC=1, MIC=1, LINE=0
     *    0x060 = 0_0110_0000 -> disable ADC, MIC; keep LINE, DAC, OUT, CLK on
     *    Actually for playback only:
     *      Bit 0: LINEINPD  = 1 (power down line in)
     *      Bit 1: MICPD     = 1 (power down mic)
     *      Bit 2: ADCPD     = 1 (power down ADC)
     *      Bit 3: DACPD     = 0 (DAC on)
     *      Bit 4: OUTPD     = 0 (output on)
     *      Bit 5: OSCPD     = 1 (oscillator off -- we supply MCLK externally)
     *      Bit 6: CLKOUTPD  = 1 (clock output off)
     *      Bit 7: POWEROFF  = 0 (device on)
     *    = 0x67
     */
    xil_printf("  Power management...\r\n");
    rc |= ssm2603_write(REG_POWER_MGMT, 0x067);

    /* 3. Digital audio interface: I2S, 16-bit, slave mode
     *    Bit 1:0 = 10 (16-bit)  -- FORMAT field is actually [3:2] for length
     *    SSM2603 R7:
     *      [1:0] FORMAT  = 10 (I2S)
     *      [3:2] IWL     = 00 (16-bit)
     *      [4]   LRP     = 0
     *      [5]   LRSWAP  = 0
     *      [6]   MS      = 0 (slave mode -- BCLK/LRCK from FPGA)
     *      [7]   BCLKINV = 0
     *    = 0x02
     */
    xil_printf("  Digital interface (I2S, 16-bit, slave)...\r\n");
    rc |= ssm2603_write(REG_DIGITAL_IF, 0x002);

    /* 4. Analog audio path: select DAC, mute mic
     *    R4: MICBOOST=0, MUTEMIC=1, INSEL=0(line), BYPASS=0, DACSEL=1, SIDETONE=0
     *    = 0x12
     */
    xil_printf("  Analog path (DAC selected)...\r\n");
    rc |= ssm2603_write(REG_ANALOG_PATH, 0x012);

    /* 5. Digital audio path: no de-emphasis, no soft mute, clear DC offset
     *    R5: ADCHPD=0, DEEMP=00, DACMU=0, HPOR=0
     *    = 0x00
     */
    xil_printf("  Digital path (no mute, no de-emphasis)...\r\n");
    rc |= ssm2603_write(REG_DIGITAL_PATH, 0x000);

    /* 6. Sample rate: normal mode, 48 kHz with MCLK = 256*Fs (12.288 MHz)
     *    R8: USB/NORMAL=0, BOSR=0, SR[3:0]=0000 -> 48 kHz
     *    = 0x00
     */
    xil_printf("  Sample rate (48 kHz, MCLK=256*Fs)...\r\n");
    rc |= ssm2603_write(REG_SAMPLE_RATE, 0x000);

    /* 7. Set headphone volume: 0 dB
     *    R2/R3: LHPVOL/RHPVOL [6:0] = 0x79 = 0 dB, bit 7 = zero-cross enable
     *    Also set bit 8 to update both channels simultaneously
     */
    xil_printf("  Headphone volume (0 dB)...\r\n");
    rc |= ssm2603_write(REG_LEFT_DAC_VOL, 0x179);
    rc |= ssm2603_write(REG_RIGHT_DAC_VOL, 0x179);

    /* 8. Activate the digital audio interface */
    xil_printf("  Activate digital core...\r\n");
    rc |= ssm2603_write(REG_ACTIVE, 0x001);

    usleep(75000); /* Wait for codec to stabilize */

    /* 9. Power on output -- clear OUTPD bit (already done above, but
     *    the datasheet recommends a delayed un-power of the output stage).
     *    Remove the OUTPD power-down after activation for clean startup:
     *    Same as step 2 but with OUTPD already 0 -- no extra write needed.
     */

    return rc;
}

int main(void)
{
    int status;

    xil_printf("\r\n============================================\r\n");
    xil_printf(" 11_audio — Zybo Audio Codec Demo\r\n");
    xil_printf(" SSM2603 I2S tone generator (750 Hz sine)\r\n");
    xil_printf("============================================\r\n\r\n");

    /* Initialize AXI IIC */
    xil_printf(">>> Initializing AXI IIC...\r\n");
    XIic_Config *cfg = XIic_LookupConfig(XPAR_XIIC_0_BASEADDR);
    if (!cfg) {
        xil_printf("ERROR: IIC config lookup failed\r\n");
        return -1;
    }

    status = XIic_CfgInitialize(&Iic, cfg, cfg->BaseAddress);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: IIC init failed (%d)\r\n", status);
        return -1;
    }

    /* Start the IIC driver (needed for polling-mode Send) */
    XIic_Start(&Iic);

    /* Configure codec */
    status = ssm2603_init();
    if (status != 0) {
        xil_printf("\r\nWARNING: Some codec writes failed. Audio may not work.\r\n");
    } else {
        xil_printf("\r\nCodec configuration complete!\r\n");
    }

    xil_printf("\r\n============================================\r\n");
    xil_printf(" Tone should now be playing on headphone jack.\r\n");
    xil_printf(" Frequency: ~750 Hz sine wave\r\n");
    xil_printf(" Sample rate: 48 kHz, 16-bit I2S\r\n");
    xil_printf("============================================\r\n\r\n");

    /* PL handles the I2S data -- nothing more to do */
    while (1) {
        /* spin */
    }

    return 0;
}
