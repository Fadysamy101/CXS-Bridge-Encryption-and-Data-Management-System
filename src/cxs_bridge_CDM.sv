// module cxs_bridge_cdm
// #(
//     parameter int DATA_WIDTH = 17,
//     parameter int ADDR_WIDTH = 8
// )
// (
//     input  logic                         i_cxs_bridge_cdm_clk,
//     input  logic                         i_cxs_bridge_cdm_rst_n,

//     input  logic                         i_cxs_bridge_cdm_wr_en,
//     input  logic [ADDR_WIDTH-1:0]        i_cxs_bridge_cdm_wr_addr,
//     input  logic [DATA_WIDTH-1:0]        i_cxs_bridge_cdm_wr_data,

//     input  logic                         i_cxs_bridge_cdm_rd_en,
//     input  logic [ADDR_WIDTH-1:0]        i_cxs_bridge_cdm_rd_addr,

//     output logic [DATA_WIDTH-1:0]        o_cxs_bridge_cdm_rd_data
// );

//     logic [DATA_WIDTH-1:0] cxs_bridge_cdm_mem [(1<<ADDR_WIDTH)-1:0];

//     always_ff @(posedge i_cxs_bridge_cdm_clk or negedge i_cxs_bridge_cdm_rst_n)
//     begin : cdm_write_proc
//         if (!i_cxs_bridge_cdm_rst_n) begin
//             o_cxs_bridge_cdm_rd_data <= '0;
//         end
//         else begin

//             if (i_cxs_bridge_cdm_wr_en)
//                 cxs_bridge_cdm_mem[i_cxs_bridge_cdm_wr_addr]<= i_cxs_bridge_cdm_wr_data;

//             if (i_cxs_bridge_cdm_rd_en)
//                 o_cxs_bridge_cdm_rd_data <= cxs_bridge_cdm_mem[i_cxs_bridge_cdm_rd_addr];

//         end
//     end

// endmodule
