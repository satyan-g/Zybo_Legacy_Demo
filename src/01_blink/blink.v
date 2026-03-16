// blink.v — Blink all 4 LEDs on Zybo Z7-10 at ~1 Hz
//
// 125 MHz system clock / 2^26 ≈ 1.86 Hz toggle → ~0.93 Hz blink

module blink (
    input  wire clk,        // 125 MHz system clock
    output wire [3:0] led   // 4 user LEDs (active high)
);

    reg [25:0] counter = 0;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    // All 4 LEDs blink together using MSB of counter
    assign led = {4{counter[25]}};

endmodule
