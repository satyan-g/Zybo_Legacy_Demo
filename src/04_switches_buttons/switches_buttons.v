// switches_buttons.v — Switches and buttons demo for Original Zybo
//
// Features:
//   - SW[3:0] directly mapped to LED[3:0] (combinational)
//   - BTN0: Toggle LED0 on press (edge-detected, debounced)
//   - BTN1: Toggle LED1 on press
//   - BTN2: Toggle LED2 on press
//   - BTN3: Shift LED pattern left on press
//
// Teaches: debouncing, edge detection, registered outputs

module switches_buttons (
    input  wire       clk,        // 125 MHz
    input  wire [3:0] sw,         // 4 slide switches
    input  wire [3:0] btn,        // 4 push buttons
    output reg  [3:0] led = 0     // 4 LEDs
);

    // =========================================================
    // Button Debouncer
    // =========================================================
    // Buttons bounce for ~5-20ms. Sample every ~10ms (125MHz/2^20 ≈ 8ms)
    // and require 3 consecutive same-value samples.

    reg [19:0] sample_counter = 0;
    wire sample_tick = (sample_counter == 0);

    always @(posedge clk)
        sample_counter <= sample_counter + 1;

    // Per-button debounce shift registers (3 samples)
    reg [2:0] btn_shift [0:3];
    reg [3:0] btn_stable = 0;
    reg [3:0] btn_prev = 0;
    wire [3:0] btn_rise;

    integer i;
    initial begin
        for (i = 0; i < 4; i = i + 1)
            btn_shift[i] = 3'b000;
    end

    always @(posedge clk) begin
        if (sample_tick) begin
            for (i = 0; i < 4; i = i + 1) begin
                btn_shift[i] <= {btn_shift[i][1:0], btn[i]};

                // Stable high: 3 consecutive 1s
                if (btn_shift[i] == 3'b111)
                    btn_stable[i] <= 1'b1;
                // Stable low: 3 consecutive 0s
                else if (btn_shift[i] == 3'b000)
                    btn_stable[i] <= 1'b0;
            end
        end
    end

    // =========================================================
    // Edge Detection — rising edge of debounced button
    // =========================================================
    always @(posedge clk)
        btn_prev <= btn_stable;

    assign btn_rise = btn_stable & ~btn_prev;

    // =========================================================
    // LED Logic — two modes selected by SW[3]
    // =========================================================
    // SW[3] = 0: Direct switch mode (SW[2:0] → LED[2:0], BTN toggles LED[3])
    // SW[3] = 1: Button mode (all 4 buttons control LEDs)

    reg [3:0] toggle_state = 0;

    always @(posedge clk) begin
        // BTN0-2: toggle individual bits
        if (btn_rise[0]) toggle_state[0] <= ~toggle_state[0];
        if (btn_rise[1]) toggle_state[1] <= ~toggle_state[1];
        if (btn_rise[2]) toggle_state[2] <= ~toggle_state[2];

        // BTN3: rotate pattern left
        if (btn_rise[3]) toggle_state <= {toggle_state[2:0], toggle_state[3]};

        // Output mux
        if (sw[3] == 1'b0)
            led <= sw;                  // Direct: switches control LEDs
        else
            led <= toggle_state;        // Button mode: toggles control LEDs
    end

endmodule
