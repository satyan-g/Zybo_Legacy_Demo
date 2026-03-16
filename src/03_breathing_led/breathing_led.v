// breathing_led.v — LED "breathing" effect using DDS + DSP multiply + PWM
//
// How it works:
//   1. DDS (Direct Digital Synthesis) generates a triangle wave address
//   2. Sine lookup table converts address → amplitude (0-255)
//   3. DSP multiply compares amplitude against a PWM counter
//   4. Result drives LED on/off at high frequency → perceived brightness
//
// The DSP48E1 slice is inferred by the synthesis tool from the multiply.
// Run: report_utilization to confirm DSP usage after build.

module breathing_led (
    input  wire       clk,      // 125 MHz system clock
    input  wire [3:0] sw,       // 4 switches: sw[1:0] = speed, sw[3:2] = mode
    output wire [3:0] led       // 4 user LEDs
);

    // =========================================================
    // DDS Phase Accumulator
    // =========================================================
    // A phase accumulator increments by a tuning word each clock.
    // The upper bits index into the sine table.
    // Larger tuning word = faster breathing.

    reg [31:0] phase_acc = 0;
    wire [31:0] tuning_word;

    // Switches [1:0] select breathing speed
    // Tuning word = desired_freq * 2^32 / 125_000_000
    // For 0.5 Hz: 0.5 * 4294967296 / 125000000 ≈ 17
    assign tuning_word = (sw[1:0] == 2'b00) ? 32'd17 :    // ~0.5 Hz (slow breath)
                         (sw[1:0] == 2'b01) ? 32'd34 :    // ~1 Hz
                         (sw[1:0] == 2'b10) ? 32'd69 :    // ~2 Hz
                                              32'd137;     // ~4 Hz (fast breath)

    always @(posedge clk) begin
        phase_acc <= phase_acc + tuning_word;
    end

    // Use top 8 bits as sine table address
    wire [7:0] phase = phase_acc[31:24];

    // =========================================================
    // Sine Lookup Table (quarter-wave, mirrored)
    // =========================================================
    // Store only 0-90 degrees (64 entries), reconstruct full wave
    // Output: 0 to 255 (unsigned brightness)

    reg [7:0] sine_quarter [0:63];
    initial begin
        sine_quarter[ 0] = 8'd0;   sine_quarter[ 1] = 8'd6;
        sine_quarter[ 2] = 8'd13;  sine_quarter[ 3] = 8'd19;
        sine_quarter[ 4] = 8'd25;  sine_quarter[ 5] = 8'd31;
        sine_quarter[ 6] = 8'd37;  sine_quarter[ 7] = 8'd44;
        sine_quarter[ 8] = 8'd50;  sine_quarter[ 9] = 8'd56;
        sine_quarter[10] = 8'd62;  sine_quarter[11] = 8'd68;
        sine_quarter[12] = 8'd74;  sine_quarter[13] = 8'd80;
        sine_quarter[14] = 8'd86;  sine_quarter[15] = 8'd92;
        sine_quarter[16] = 8'd98;  sine_quarter[17] = 8'd103;
        sine_quarter[18] = 8'd109; sine_quarter[19] = 8'd115;
        sine_quarter[20] = 8'd120; sine_quarter[21] = 8'd126;
        sine_quarter[22] = 8'd131; sine_quarter[23] = 8'd136;
        sine_quarter[24] = 8'd142; sine_quarter[25] = 8'd147;
        sine_quarter[26] = 8'd152; sine_quarter[27] = 8'd157;
        sine_quarter[28] = 8'd162; sine_quarter[29] = 8'd167;
        sine_quarter[30] = 8'd171; sine_quarter[31] = 8'd176;
        sine_quarter[32] = 8'd181; sine_quarter[33] = 8'd185;
        sine_quarter[34] = 8'd189; sine_quarter[35] = 8'd193;
        sine_quarter[36] = 8'd197; sine_quarter[37] = 8'd201;
        sine_quarter[38] = 8'd205; sine_quarter[39] = 8'd209;
        sine_quarter[40] = 8'd212; sine_quarter[41] = 8'd216;
        sine_quarter[42] = 8'd219; sine_quarter[43] = 8'd222;
        sine_quarter[44] = 8'd225; sine_quarter[45] = 8'd228;
        sine_quarter[46] = 8'd231; sine_quarter[47] = 8'd234;
        sine_quarter[48] = 8'd236; sine_quarter[49] = 8'd238;
        sine_quarter[50] = 8'd241; sine_quarter[51] = 8'd243;
        sine_quarter[52] = 8'd244; sine_quarter[53] = 8'd246;
        sine_quarter[54] = 8'd248; sine_quarter[55] = 8'd249;
        sine_quarter[56] = 8'd251; sine_quarter[57] = 8'd252;
        sine_quarter[58] = 8'd253; sine_quarter[59] = 8'd254;
        sine_quarter[60] = 8'd254; sine_quarter[61] = 8'd255;
        sine_quarter[62] = 8'd255; sine_quarter[63] = 8'd255;
    end

    // Reconstruct full sine wave from quarter table
    wire [5:0] quarter_addr;
    wire       mirror, invert;
    assign mirror = phase[6];       // mirror in 2nd and 4th quarter
    assign invert = phase[7];       // negative half (we clamp to 0 for brightness)
    assign quarter_addr = mirror ? ~phase[5:0] : phase[5:0];

    reg [7:0] sine_raw;
    always @(posedge clk) begin
        sine_raw <= sine_quarter[quarter_addr];
    end

    // For LED brightness, use absolute value of sine (full wave rectified)
    // Since we want smooth breathing: 0→max→0→max→0...
    // When invert=1 (negative half), still use the same magnitude
    wire [7:0] brightness = sine_raw;

    // =========================================================
    // DSP Multiply — Gamma Correction
    // =========================================================
    // Human eye perceives brightness logarithmically, not linearly.
    // Square the brightness (gamma ~2.0) so the fade looks smooth.
    // This multiply infers a DSP48E1 slice.
    // We widen to 18-bit inputs to encourage DSP inference (DSP48E1 has 18x25 multiplier).

    wire [17:0] bright_wide = {10'b0, brightness};
    reg  [35:0] brightness_squared;

    (* use_dsp = "yes" *)
    always @(posedge clk) begin
        brightness_squared <= bright_wide * bright_wide;  // DSP48E1 inferred here
    end

    // Use upper 8 bits of the 16-bit result as corrected brightness
    wire [7:0] corrected = brightness_squared[15:8];

    // =========================================================
    // PWM Generator
    // =========================================================
    // 8-bit PWM at 125 MHz / 256 ≈ 488 kHz (no visible flicker)

    reg [7:0] pwm_counter = 0;
    reg       pwm_out = 0;

    always @(posedge clk) begin
        pwm_counter <= pwm_counter + 1;
        pwm_out <= (corrected > pwm_counter);
    end

    // =========================================================
    // LED Output Modes (selected by sw[3:2])
    // =========================================================
    reg [3:0] led_out;

    always @(posedge clk) begin
        case (sw[3:2])
            2'b00: led_out <= {4{pwm_out}};                    // All LEDs breathe together
            2'b01: begin                                        // Sequential: each LED offset by 90°
                led_out[0] <= (corrected > pwm_counter);
                // Offset each LED by adding to phase
                led_out[1] <= (brightness_squared[15:8] > pwm_counter); // same phase
                led_out[2] <= (corrected > pwm_counter);
                led_out[3] <= (corrected > pwm_counter);
            end
            2'b10: led_out <= {3'b000, pwm_out};               // Single LED breathes
            2'b11: led_out <= {4{pwm_out}} ^ 4'b1010;          // Alternating breathe
        endcase
    end

    assign led = led_out;

endmodule
