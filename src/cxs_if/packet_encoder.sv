
module packet_encoder #(
  parameter int CXS_DATA_WIDTH = 256,
  parameter int CXS_CNTL_WIDTH = 14
)(
  input  logic                      i_packet_encoder_clk,
  input  logic                      i_packet_encoder_rst_n,

  input  logic                      i_packet_encoder_error_valid_sync,
  input  logic [1:0]                i_packet_encoder_error_in,

  output logic [CXS_DATA_WIDTH-1:0] o_packet_encoder_flit_tx,
  output logic [CXS_CNTL_WIDTH-1:0] o_packet_encoder_flit_cntrl,
  output logic                      o_packet_encoder_flit_valid
);

  localparam logic [7:0] RESP_OPCODE_ERROR = 8'hE0;

  // Control field layout as decoded by the packet formatter: START[0] is bit 0,
  // END[0] is bit 4. The response is a single word, so both are set and the
  // start/end pointers stay at 0.
  localparam int CNTL_START_BIT = 0;
  localparam int CNTL_END_BIT   = 4;

  logic error_valid_sync_d0;

  // One response packet per assertion: a level that stays high must not keep
  // re-issuing FLITs.
  wire error_event = i_packet_encoder_error_valid_sync && !error_valid_sync_d0;

  logic [31:0] resp_word;
  always_comb begin: resp_word_proc
    resp_word       = '0;
    resp_word[15:8] = RESP_OPCODE_ERROR;
    resp_word[1:0]  = i_packet_encoder_error_in;
  end

  logic [CXS_CNTL_WIDTH-1:0] resp_cntl;
  always_comb begin: resp_cntl_proc
    resp_cntl                 = '0;
    resp_cntl[CNTL_START_BIT] = 1'b1;
    resp_cntl[CNTL_END_BIT]   = 1'b1;
  end

  always_ff @(posedge i_packet_encoder_clk or negedge i_packet_encoder_rst_n) begin: flit_tx_proc
    if (!i_packet_encoder_rst_n) begin
      error_valid_sync_d0         <= 1'b0;
      o_packet_encoder_flit_tx    <= '0;
      o_packet_encoder_flit_cntrl <= '0;
      o_packet_encoder_flit_valid <= 1'b0;
    end
    else begin
      error_valid_sync_d0         <= i_packet_encoder_error_valid_sync;
      o_packet_encoder_flit_valid <= error_event;

      if (error_event) begin
        o_packet_encoder_flit_tx    <= {{(CXS_DATA_WIDTH-32){1'b0}}, resp_word};
        o_packet_encoder_flit_cntrl <= resp_cntl;
      end
    end
  end

endmodule
