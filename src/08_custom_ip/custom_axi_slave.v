// custom_axi_slave.v — AXI4-Lite slave peripheral with 4 registers
//
// Reg0 (0x00): LED output register      — write LEDs[3:0]
// Reg1 (0x04): Switch input register    — read-only, switches[3:0]
// Reg2 (0x08): Scratch register          — read/write
// Reg3 (0x0C): Counter register          — read-only, free-running 32-bit counter
//
// AXI4-Lite slave interface — 32-bit data, 4-byte aligned addresses

module custom_axi_slave #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 4     // 4 registers = 16 bytes => 4-bit addr
)(
    // AXI4-Lite Slave Interface
    input  wire                              S_AXI_ACLK,
    input  wire                              S_AXI_ARESETN,

    // Write address channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     S_AXI_AWADDR,
    input  wire                              S_AXI_AWVALID,
    output wire                              S_AXI_AWREADY,

    // Write data channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                              S_AXI_WVALID,
    output wire                              S_AXI_WREADY,

    // Write response channel
    output wire [1:0]                        S_AXI_BRESP,
    output wire                              S_AXI_BVALID,
    input  wire                              S_AXI_BREADY,

    // Read address channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     S_AXI_ARADDR,
    input  wire                              S_AXI_ARVALID,
    output wire                              S_AXI_ARREADY,

    // Read data channel
    output wire [C_S_AXI_DATA_WIDTH-1:0]     S_AXI_RDATA,
    output wire [1:0]                        S_AXI_RRESP,
    output wire                              S_AXI_RVALID,
    input  wire                              S_AXI_RREADY,

    // User ports
    output wire [3:0]                        leds,
    input  wire [3:0]                        switches
);

    // -------------------------------------------------------
    // Internal signals
    // -------------------------------------------------------
    reg                              axi_awready;
    reg                              axi_wready;
    reg [1:0]                        axi_bresp;
    reg                              axi_bvalid;
    reg                              axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1:0]     axi_rdata;
    reg [1:0]                        axi_rresp;
    reg                              axi_rvalid;

    // Latched write address
    reg [C_S_AXI_ADDR_WIDTH-1:0]     axi_awaddr;
    // Latched read address
    reg [C_S_AXI_ADDR_WIDTH-1:0]     axi_araddr;

    // Registers
    reg [C_S_AXI_DATA_WIDTH-1:0]     reg_led;       // Reg0 — LED output
    // reg_switch is combinational (direct input)
    reg [C_S_AXI_DATA_WIDTH-1:0]     reg_scratch;   // Reg2 — scratch
    reg [C_S_AXI_DATA_WIDTH-1:0]     reg_counter;   // Reg3 — free-running counter

    // Write handshake tracking
    reg aw_en;

    // -------------------------------------------------------
    // Output assignments
    // -------------------------------------------------------
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    assign leds = reg_led[3:0];

    // -------------------------------------------------------
    // Free-running counter (Reg3)
    // -------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN)
            reg_counter <= 32'd0;
        else
            reg_counter <= reg_counter + 1;
    end

    // -------------------------------------------------------
    // Write Address Channel — AWREADY
    // -------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            axi_awready <= 1'b0;
            aw_en       <= 1'b1;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1;
                aw_en       <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en       <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // Latch write address
    always @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN)
            axi_awaddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        else if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
            axi_awaddr <= S_AXI_AWADDR;
    end

    // -------------------------------------------------------
    // Write Data Channel — WREADY
    // -------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN)
            axi_wready <= 1'b0;
        else if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en)
            axi_wready <= 1'b1;
        else
            axi_wready <= 1'b0;
    end

    // -------------------------------------------------------
    // Register Write Logic (with byte strobes)
    // -------------------------------------------------------
    wire wr_en;
    assign wr_en = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            reg_led     <= 32'd0;
            reg_scratch <= 32'd0;
        end else if (wr_en) begin
            case (axi_awaddr[3:2])
                2'b00: begin // Reg0 — LED register
                    if (S_AXI_WSTRB[0]) reg_led[ 7: 0] <= S_AXI_WDATA[ 7: 0];
                    if (S_AXI_WSTRB[1]) reg_led[15: 8] <= S_AXI_WDATA[15: 8];
                    if (S_AXI_WSTRB[2]) reg_led[23:16] <= S_AXI_WDATA[23:16];
                    if (S_AXI_WSTRB[3]) reg_led[31:24] <= S_AXI_WDATA[31:24];
                end
                2'b01: begin // Reg1 — Switch register (read-only, writes ignored)
                end
                2'b10: begin // Reg2 — Scratch register
                    if (S_AXI_WSTRB[0]) reg_scratch[ 7: 0] <= S_AXI_WDATA[ 7: 0];
                    if (S_AXI_WSTRB[1]) reg_scratch[15: 8] <= S_AXI_WDATA[15: 8];
                    if (S_AXI_WSTRB[2]) reg_scratch[23:16] <= S_AXI_WDATA[23:16];
                    if (S_AXI_WSTRB[3]) reg_scratch[31:24] <= S_AXI_WDATA[31:24];
                end
                2'b11: begin // Reg3 — Counter register (read-only, writes ignored)
                end
            endcase
        end
    end

    // -------------------------------------------------------
    // Write Response Channel
    // -------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b00;  // OKAY
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b00;  // OKAY
            end else if (S_AXI_BREADY && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------
    // Read Address Channel — ARREADY
    // -------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            axi_arready <= 1'b0;
            axi_araddr  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------
    // Read Data Channel — RVALID / RDATA
    // -------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b00;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b00;  // OKAY
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // Register read mux
    always @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            axi_rdata <= 32'd0;
        end else if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
            case (axi_araddr[3:2])
                2'b00: axi_rdata <= reg_led;
                2'b01: axi_rdata <= {28'd0, switches};
                2'b10: axi_rdata <= reg_scratch;
                2'b11: axi_rdata <= reg_counter;
            endcase
        end
    end

endmodule
