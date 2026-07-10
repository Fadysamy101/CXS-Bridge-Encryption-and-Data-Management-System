module cxs_bridge_parity_check # (parameter DATA_WIDTH =16 )
( input logic i_cxs_bridge_parity_check_parity_slc,
  input logic  [DATA_WIDTH-1:0] i_cxs_bridge_parity_check_data_in,
  output logic [DATA_WIDTH:0] o_cxs_bridge_parity_check_data_out
);
  bit i_cxs_bridge_parity_check_data_in_even_parity_bit;
  assign i_cxs_bridge_parity_check_data_in_even_parity_bit=^i_cxs_bridge_parity_check_data_in;
  always_comb begin : parity_append_proc
    if(i_cxs_bridge_parity_check_parity_slc)
      o_cxs_bridge_parity_check_data_out = {i_cxs_bridge_parity_check_data_in_even_parity_bit,i_cxs_bridge_parity_check_data_in};
    else
      o_cxs_bridge_parity_check_data_out = {~i_cxs_bridge_parity_check_data_in_even_parity_bit,i_cxs_bridge_parity_check_data_in};
  end
endmodule
