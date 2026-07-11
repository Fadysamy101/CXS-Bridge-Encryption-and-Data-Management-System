module cxs_bridge_enc_unit #(
    parameter int IN_WIDTH  = 16,
    parameter int OUT_WIDTH = 2 * IN_WIDTH
) (
    input  logic [IN_WIDTH-1:0]  cxs_bridge_enc_unit_data_in,
    input  logic [3:0]           cxs_bridge_enc_unit_enc_mode,
    output logic [OUT_WIDTH-1:0] cxs_bridge_enc_unit_data_out

);

    logic [$clog2(IN_WIDTH+1)-1:0] count_ones;
    logic [$clog2(IN_WIDTH+1)-1:0] count_zeros;

    always_comb begin
        count_ones = '0;
        for (int i = 0; i < IN_WIDTH; i++)
            count_ones += cxs_bridge_enc_unit_data_in[i];
        count_zeros = IN_WIDTH - count_ones;
    end

    logic counts_equal;
    logic both_even;
    logic note_condition;

    assign counts_equal   = (count_ones == count_zeros);
    assign both_even      = (count_ones[0] == 1'b0) && (count_zeros[0] == 1'b0);
    assign note_condition = counts_equal || both_even;

    logic [OUT_WIDTH-1:0] dup_result;

    always_comb begin
        for (int i = 0; i < IN_WIDTH; i++)
            dup_result[2*i +: 2] = {cxs_bridge_enc_unit_data_in[i], cxs_bridge_enc_unit_data_in[i]};
    end

    logic [OUT_WIDTH-1:0] map_result;

    always_comb begin
        for (int i = 0; i < IN_WIDTH; i++)
            map_result[2*i +: 2] = cxs_bridge_enc_unit_data_in[i] ? 2'b10 : 2'b01;
    end

    always_comb begin
        cxs_bridge_enc_unit_data_out   = '0;


        unique case (cxs_bridge_enc_unit_enc_mode)
            4'b0000: begin
                cxs_bridge_enc_unit_data_out = dup_result;
            end

            4'b0001: begin
                if (note_condition) begin
                    cxs_bridge_enc_unit_data_out = map_result;
                end else begin
                    cxs_bridge_enc_unit_data_out   = {{(OUT_WIDTH-IN_WIDTH){1'b0}}, cxs_bridge_enc_unit_data_in};
                end
            end

            default: begin
                cxs_bridge_enc_unit_data_out = '0;
            end
        endcase
    end

endmodule