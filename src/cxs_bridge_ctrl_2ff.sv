module cxs_bridge_ctrl_2ff
(  input  logic i_cxs_bridge_ctrl_2ff_clk,
   input  logic i_cxs_bridge_ctrl_2ff_rst_n,
   input  logic i_cxs_bridge_ctrl_2ff_ctrl_in,
   output logic o_cxs_bridge_ctrl_2ff_sync_ctrl_out 

); 
  logic cxs_bridge_ctrl_2ff_ctrl_in_d0;
  
 always_ff @(posedge i_cxs_bridge_ctrl_2ff_clk or negedge i_cxs_bridge_ctrl_2ff_rst_n) 

  begin: ctrl_sync_proc
    if (!i_cxs_bridge_ctrl_2ff_rst_n) begin
        o_cxs_bridge_ctrl_2ff_sync_ctrl_out <= 1'b0;
        cxs_bridge_ctrl_2ff_ctrl_in_d0 <= 1'b0;
    end else begin
        cxs_bridge_ctrl_2ff_ctrl_in_d0 <= i_cxs_bridge_ctrl_2ff_ctrl_in;
        o_cxs_bridge_ctrl_2ff_sync_ctrl_out <= cxs_bridge_ctrl_2ff_ctrl_in_d0;
    end
  end

endmodule