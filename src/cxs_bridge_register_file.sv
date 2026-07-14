module cxs_bridge_register_file #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 8
)(
    input  logic                          i_cxs_bridge_register_file_clk,
    input  logic                          i_cxs_bridge_register_file_rst_n,
    input  logic [DATA_WIDTH-1:0]         i_cxs_bridge_register_file_wdata,
    input  logic [ADDR_WIDTH-1:0]         i_cxs_bridge_register_file_addr,
    input  logic                          i_cxs_bridge_register_file_write_en,
    input  logic                          i_cxs_bridge_register_file_read_en,

    output logic [DATA_WIDTH-1:0]         o_cxs_bridge_register_file_rdata,
    output logic                          o_cxs_bridge_read_valid
);

logic [31:0] mem [2**ADDR_WIDTH-1:0];

always_ff @(posedge i_cxs_bridge_register_file_clk or negedge i_cxs_bridge_register_file_rst_n) begin
    if (!i_cxs_bridge_register_file_rst_n) begin
        mem[0] <= '0;
        mem[1] <= '0;
        mem[2] <= '0;
        mem[3] <= '0;

        o_cxs_bridge_register_file_rdata <= '0;
        o_cxs_bridge_read_valid <= 1'b0;
    end
    else begin
        if (i_cxs_bridge_register_file_write_en) begin
            mem[i_cxs_bridge_register_file_addr] <=i_cxs_bridge_register_file_wdata;
        end

        if (i_cxs_bridge_register_file_read_en) begin
            o_cxs_bridge_register_file_rdata <=mem[i_cxs_bridge_register_file_addr];
            o_cxs_bridge_read_valid <= 1'b1;
        end
        else begin
            o_cxs_bridge_read_valid <= 1'b0;
        end
    end
end

endmodule