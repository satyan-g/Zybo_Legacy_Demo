// i2s_tone_gen.v — I2S tone generator for SSM2603 codec on Zybo
//
// Generates BCLK, LRCK, and I2S-formatted 16-bit sine wave data from a
// lookup table. Designed for 48 kHz sample rate with 12.288 MHz MCLK input.
//
// I2S timing (standard Philips format):
//   MCLK  = 12.288 MHz (256 * Fs)
//   BCLK  = MCLK / 4 = 3.072 MHz (64 * Fs)
//   LRCK  = BCLK / 64 = 48 kHz
//   Data is MSB-first, one clock delay after LRCK transition

module i2s_tone_gen (
    input  wire        mclk,       // 12.288 MHz master clock
    input  wire        reset_n,    // Active-low reset
    output reg         ac_bclk,    // Bit clock to codec
    output reg         ac_pblrc,   // Playback left/right clock (LRCK)
    output reg         ac_pbdat,   // Playback data (I2S serial)
    output wire        ac_muten    // Codec mute control (active high = unmuted)
);

    // Always unmuted
    assign ac_muten = 1'b1;

    // ========================================================
    // BCLK generation: MCLK / 4 = 3.072 MHz
    // ========================================================
    reg [1:0] mclk_div;

    always @(posedge mclk or negedge reset_n) begin
        if (!reset_n)
            mclk_div <= 2'd0;
        else
            mclk_div <= mclk_div + 1;
    end

    // BCLK toggles at MCLK/4 rate
    always @(posedge mclk or negedge reset_n) begin
        if (!reset_n)
            ac_bclk <= 1'b0;
        else
            ac_bclk <= mclk_div[1];
    end

    // ========================================================
    // Bit counter: counts 0..63 within each BCLK period
    // Bits 0-31: left channel, Bits 32-63: right channel
    // ========================================================
    reg [5:0] bit_cnt;
    // Detect rising edge of BCLK (mclk_div transitions 01->10)
    wire bclk_rising = (mclk_div == 2'b01);

    always @(posedge mclk or negedge reset_n) begin
        if (!reset_n)
            bit_cnt <= 6'd0;
        else if (bclk_rising)
            bit_cnt <= bit_cnt + 1;
    end

    // ========================================================
    // LRCK generation: low = left channel, high = right channel
    // ========================================================
    always @(posedge mclk or negedge reset_n) begin
        if (!reset_n)
            ac_pblrc <= 1'b0;
        else if (bclk_rising)
            ac_pblrc <= bit_cnt[5]; // MSB of 6-bit counter
    end

    // ========================================================
    // Sine wave lookup table — 64 samples, 16-bit signed
    // 440 Hz tone at 48 kHz sample rate needs ~109 samples/cycle
    // We use a 64-entry table and step through it to approximate
    // a tone around 750 Hz (48000/64 = 750 Hz) — clearly audible
    // ========================================================
    reg [5:0] sample_idx;
    reg signed [15:0] sample_val;

    // Advance sample index at each LRCK period (once per 64 BCLK)
    always @(posedge mclk or negedge reset_n) begin
        if (!reset_n)
            sample_idx <= 6'd0;
        else if (bclk_rising && bit_cnt == 6'd63)
            sample_idx <= sample_idx + 1;
    end

    // 64-entry sine LUT (16-bit signed, amplitude ~0.9 * 32767)
    always @(*) begin
        case (sample_idx)
            6'd0:  sample_val = 16'sd0;
            6'd1:  sample_val = 16'sd2873;
            6'd2:  sample_val = 16'sd5720;
            6'd3:  sample_val = 16'sd8514;
            6'd4:  sample_val = 16'sd11230;
            6'd5:  sample_val = 16'sd13842;
            6'd6:  sample_val = 16'sd16327;
            6'd7:  sample_val = 16'sd18661;
            6'd8:  sample_val = 16'sd20824;
            6'd9:  sample_val = 16'sd22795;
            6'd10: sample_val = 16'sd24558;
            6'd11: sample_val = 16'sd26098;
            6'd12: sample_val = 16'sd27402;
            6'd13: sample_val = 16'sd28461;
            6'd14: sample_val = 16'sd29268;
            6'd15: sample_val = 16'sd29821;
            6'd16: sample_val = 16'sd30117;
            6'd17: sample_val = 16'sd29821;
            6'd18: sample_val = 16'sd29268;
            6'd19: sample_val = 16'sd28461;
            6'd20: sample_val = 16'sd27402;
            6'd21: sample_val = 16'sd26098;
            6'd22: sample_val = 16'sd24558;
            6'd23: sample_val = 16'sd22795;
            6'd24: sample_val = 16'sd20824;
            6'd25: sample_val = 16'sd18661;
            6'd26: sample_val = 16'sd16327;
            6'd27: sample_val = 16'sd13842;
            6'd28: sample_val = 16'sd11230;
            6'd29: sample_val = 16'sd8514;
            6'd30: sample_val = 16'sd5720;
            6'd31: sample_val = 16'sd2873;
            6'd32: sample_val = 16'sd0;
            6'd33: sample_val = -16'sd2873;
            6'd34: sample_val = -16'sd5720;
            6'd35: sample_val = -16'sd8514;
            6'd36: sample_val = -16'sd11230;
            6'd37: sample_val = -16'sd13842;
            6'd38: sample_val = -16'sd16327;
            6'd39: sample_val = -16'sd18661;
            6'd40: sample_val = -16'sd20824;
            6'd41: sample_val = -16'sd22795;
            6'd42: sample_val = -16'sd24558;
            6'd43: sample_val = -16'sd26098;
            6'd44: sample_val = -16'sd27402;
            6'd45: sample_val = -16'sd28461;
            6'd46: sample_val = -16'sd29268;
            6'd47: sample_val = -16'sd29821;
            6'd48: sample_val = -16'sd30117;
            6'd49: sample_val = -16'sd29821;
            6'd50: sample_val = -16'sd29268;
            6'd51: sample_val = -16'sd28461;
            6'd52: sample_val = -16'sd27402;
            6'd53: sample_val = -16'sd26098;
            6'd54: sample_val = -16'sd24558;
            6'd55: sample_val = -16'sd22795;
            6'd56: sample_val = -16'sd20824;
            6'd57: sample_val = -16'sd18661;
            6'd58: sample_val = -16'sd16327;
            6'd59: sample_val = -16'sd13842;
            6'd60: sample_val = -16'sd11230;
            6'd61: sample_val = -16'sd8514;
            6'd62: sample_val = -16'sd5720;
            6'd63: sample_val = -16'sd2873;
        endcase
    end

    // ========================================================
    // I2S shift register: MSB-first, 16-bit data in 32-bit slot
    // Data transitions on falling edge of BCLK (sampled on rising)
    // I2S: data is delayed 1 BCLK after LRCK transition
    // ========================================================
    reg [31:0] shift_reg;
    wire bclk_falling = (mclk_div == 2'b11);

    // Load shift register at start of each channel slot
    // bit_cnt == 0 -> start of left, bit_cnt == 32 -> start of right
    always @(posedge mclk or negedge reset_n) begin
        if (!reset_n) begin
            shift_reg <= 32'd0;
        end else if (bclk_falling) begin
            if (bit_cnt == 6'd0 || bit_cnt == 6'd32) begin
                // Load: 16-bit sample in upper bits, lower 16 bits zero-padded
                shift_reg <= {sample_val, 16'd0};
            end else begin
                shift_reg <= {shift_reg[30:0], 1'b0};
            end
        end
    end

    // Output the MSB of shift register as serial data
    always @(posedge mclk or negedge reset_n) begin
        if (!reset_n)
            ac_pbdat <= 1'b0;
        else if (bclk_falling)
            ac_pbdat <= shift_reg[31];
    end

endmodule
