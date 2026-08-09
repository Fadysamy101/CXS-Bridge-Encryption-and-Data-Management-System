
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
    output logic [1:0]                  parity_mode,


);

    localparam int WORD_WIDTH = (DATA_WIDTH*2) + 1;

    localparam logic [ADDR_WIDTH-1:0] CFG_ADDR  = ADDR_WIDTH'('h0000);
    localparam logic [ADDR_WIDTH-1:0] DEV_BASE  = ADDR_WIDTH'('h0001);
    localparam logic [ADDR_WIDTH-1:0] DEV_TOP   = ADDR_WIDTH'('h00FF);
    localparam logic [ADDR_WIDTH-1:0] DATA_BASE = ADDR_WIDTH'('h0100);

    localparam int MEM_DEPTH = (1 << ADDR_WIDTH) - int'(DATA_BASE);

    logic [WORD_WIDTH-1:0] cfg_reg;
    logic [WORD_WIDTH-1:0] dev_cfg [DEV_MAX];
    logic [WORD_WIDTH-1:0] mem     [MEM_DEPTH];

    wire in_cfg  = (w_addr == CFG_ADDR);
    wire in_dev  = (w_addr >= DEV_BASE) && (w_addr <= DEV_TOP);
    wire in_data = (w_addr >= DATA_BASE);

    wire [ADDR_WIDTH-1:0] w_dev_idx = w_addr - DEV_BASE;
    wire [ADDR_WIDTH-1:0] r_dev_idx = r_addr - DEV_BASE;

    // -----------------------------------------------------------------------
    // Configuration registers - reset, unlike the data array
    // -----------------------------------------------------------------------
    always_ff @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            cfg_reg <= '0;
            for (int i = 0; i < DEV_MAX; i++)
                dev_cfg[i] <= '0;
        end
        else if (w_en) begin
            if (in_cfg)
                cfg_reg <= wdata;
            else if (in_dev && (w_dev_idx < ADDR_WIDTH'(DEV_MAX)))
                dev_cfg[w_dev_idx] <= wdata;
        end
    end

    // -----------------------------------------------------------------------
    // Payload storage
    // -----------------------------------------------------------------------
    always_ff @(posedge clk_sys) begin
        if (w_en && in_data)
            mem[w_addr - DATA_BASE] <= wdata;
    end


    // -----------------------------------------------------------------------
    // Configuration taps
    // -----------------------------------------------------------------------
    assign addr_mode   = cfg_reg[16];
    assign dev_count   = cfg_reg[15:8];
    assign enc_mode    = cfg_reg[7:4];
    assign parity_mode = cfg_reg[3:2];

    always_comb begin
        for (int i = 0; i < DEV_MAX; i++) begin
            dev_start_flat[i*ADDR_WIDTH +: ADDR_WIDTH] = dev_cfg[i][15:0];
            dev_end_flat  [i*ADDR_WIDTH +: ADDR_WIDTH] = dev_cfg[i][31:16];
        end
    end

endmodule
