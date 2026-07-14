module cxs_bridge_enc_unit #(
    parameter int IN_WIDTH  = 16,
    parameter int OUT_WIDTH = 2 * IN_WIDTH
) ( input  logic                 cxs_bridge_enc_unit_clk,
    input  logic                 cxs_bridge_enc_unit_rst_n,
    input  logic [IN_WIDTH-1:0]  cxs_bridge_enc_unit_data_in,
    input  logic [3:0]           cxs_bridge_enc_unit_enc_mode,
    output logic [OUT_WIDTH-1:0] cxs_bridge_enc_unit_data_out,
    output logic invalid_enc_mod

);

    logic [$clog2(IN_WIDTH+1)-1:0] count_ones;
    logic [$clog2(IN_WIDTH+1)-1:0] count_zeros;

    always_comb begin

        count_ones = '0;
        for (int i = 0; i < IN_WIDTH; i++)
          count_ones += cxs_bridge_enc_unit_data_in[i];

        count_zeros = IN_WIDTH - count_ones;

    end


    //If the counts of 0s and 1s are equal, or if both counts are even,
    // the expansion shall map '0' to '01' and '1' to '10' (e.g., input '10' becomes '1001').
    logic counts_equal;
    logic both_even;
    logic expansion_condition;

    assign counts_equal   = (count_ones == count_zeros);
    assign both_even      = (count_ones[0] == 1'b0) && (count_zeros[0] == 1'b0);
    assign expansion_condition = counts_equal || both_even;

    always_ff @(posedge cxs_bridge_enc_unit_clk or negedge cxs_bridge_enc_unit_rst_n) begin
        if (!cxs_bridge_enc_unit_rst_n) begin
            cxs_bridge_enc_unit_data_out <= '0;
            invalid_enc_mod <= 1'b0;
        end
        else begin
          if(expansion_condition)begin
            for (int i = 0; i < IN_WIDTH; i++)
              cxs_bridge_enc_unit_data_out[2*i +: 2] <= (cxs_bridge_enc_unit_data_in[i]) ? 2'b10 : 2'b01;  
          end
          else 
          begin
            case (cxs_bridge_enc_unit_enc_mode)
              4'b0001: begin:even_enc_mod
                for (int i = 0; i < IN_WIDTH; i++)
                  cxs_bridge_enc_unit_data_out[2*i +: 2] <= {1'b0,cxs_bridge_enc_unit_data_in[i]};
              end
              4'b0010: begin:odd_enc_mode
                for (int i = 0; i < IN_WIDTH; i++)
                  cxs_bridge_enc_unit_data_out[2*i +: 2] <= {1'b1,cxs_bridge_enc_unit_data_in[i]};
              end
              default: begin
                invalid_enc_mod <= 1'b1;
              end
            endcase
          end    
          
        end  
    end  
   

endmodule
