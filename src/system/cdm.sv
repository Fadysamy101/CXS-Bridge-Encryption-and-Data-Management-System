
module cdm #(
    parameter int ADDR_WIDTH = 16,
    parameter int DATA_WIDTH = 16,
    parameter int DEV_MAX    = 8
)(
    input  logic                        clk_sys,
    input  logic                        rst_n,

    input  logic                        r_en,
    input  logic [ADDR_WIDTH-1:0]       r_addr,
    output logic [(DATA_WIDTH*2):0]     rdata,     // (DATA_WIDTH*2)+1 bits

    input  logic                        w_en,
    input  logic [ADDR_WIDTH-1:0]       w_addr,
    input  logic [(DATA_WIDTH*2):0]     wdata,

    // Configuration parameters published to the rest of the system
    output logic [7:0]                  dev_count,
    output logic                        addr_mode,
    output logic [3:0]                  enc_mode,
    output logic                        parity_mode
);

    localparam int WORD_WIDTH = (DATA_WIDTH*2) + 1;
    localparam int MEM_DEPTH  = 1 << ADDR_WIDTH;

    // CDM map (spec 10.1)
    localparam logic [ADDR_WIDTH-1:0] CFG_ADDR = ADDR_WIDTH'('h0000);
    localparam logic [ADDR_WIDTH-1:0] DEV_BASE = ADDR_WIDTH'('h0001);

    logic [WORD_WIDTH-1:0] mem [MEM_DEPTH];

    // Reset clears the configuration region only; the data region behaves like
    // an ordinary memory and keeps whatever was written to it.
    always_ff @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            mem[CFG_ADDR] <= '0;
            for (int i = 0; i < DEV_MAX; i++)
                mem[DEV_BASE + ADDR_WIDTH'(i)] <= '0;
        end
        else if (w_en) begin
            mem[w_addr] <= wdata;
        end
    end

    always_ff @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n)
            rdata <= '0;
        else if (r_en)
            rdata <= mem[r_addr];
    end

    // Global configuration register taps (spec 6.2.1)
    assign dev_count   = mem[CFG_ADDR][15:8];
    assign enc_mode    = mem[CFG_ADDR][7:4];
    assign addr_mode   = mem[CFG_ADDR][3];
    assign parity_mode = mem[CFG_ADDR][2];

endmodule
