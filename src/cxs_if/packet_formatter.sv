module packet_formatter #(
  parameter int CXS_DATA_WIDTH   = 256,
  parameter int CXS_CNTL_WIDTH   = 14,
  parameter int WORD_WIDTH       = 32,
  parameter int CXSMAXPKTPERFLIT = 2,
  parameter int FLIT_WIDTH       = CXS_DATA_WIDTH + CXS_CNTL_WIDTH
)(
  input  logic                  i_packet_formatter_rst_n,
  input  logic                  i_packet_formatter_clk,

  input  logic                  i_packet_formatter_flit_fifo_empty,
  input  logic [FLIT_WIDTH-1:0] i_packet_formatter_flit_fifo_rdata,
  input  logic                  i_packet_formatter_async_fifo_full,

  output logic                  o_packet_formatter_flit_fifo_rd,
  output logic                  o_packet_formatter_async_fifo_w_en,
  output logic [WORD_WIDTH-1:0] o_packet_formatter_async_fifo_w_data
);
  //TODO Cross flit is not supported and end_error does nothing

  localparam int WORDS_PER_FLIT  = CXS_DATA_WIDTH / WORD_WIDTH;
  localparam int WCNT_WIDTH      = $clog2(WORDS_PER_FLIT);
  localparam int START_PTR_WIDTH = $clog2(CXS_DATA_WIDTH / 128);
  localparam int END_PTR_WIDTH   = $clog2(CXS_DATA_WIDTH / 32);

  logic [WCNT_WIDTH-1:0]       word_count;
  logic [CXS_CNTL_WIDTH-1:0]   cxs_ctrl;

  logic [CXSMAXPKTPERFLIT-1:0] start;
  logic [CXSMAXPKTPERFLIT-1:0] end_;
  logic [CXSMAXPKTPERFLIT-1:0] end_error;
  logic [CXS_DATA_WIDTH-1:0]   current_flit_data;
  logic                        word_valid;

  logic [START_PTR_WIDTH-1:0]  start_ptr  [CXSMAXPKTPERFLIT];
  logic [WCNT_WIDTH-1:0]       start_word [CXSMAXPKTPERFLIT];
  logic [END_PTR_WIDTH-1:0]    end_ptr    [CXSMAXPKTPERFLIT];

  localparam int START_BASE     = 0;
  localparam int START_PTR_BASE = START_BASE + CXSMAXPKTPERFLIT;
  localparam int END_BASE       = START_PTR_BASE +
                                  CXSMAXPKTPERFLIT * START_PTR_WIDTH;
  localparam int END_ERROR_BASE = END_BASE + CXSMAXPKTPERFLIT;
  localparam int END_PTR_BASE   = END_ERROR_BASE + CXSMAXPKTPERFLIT;

  assign start =
      cxs_ctrl[START_BASE + CXSMAXPKTPERFLIT - 1 : START_BASE];

  assign end_ =
      cxs_ctrl[END_BASE + CXSMAXPKTPERFLIT - 1 : END_BASE];

  assign end_error =
      cxs_ctrl[
          END_ERROR_BASE + CXSMAXPKTPERFLIT - 1 :
          END_ERROR_BASE
      ];

  assign o_packet_formatter_async_fifo_w_data = (current_state == S_STREAM)?
      current_flit_data[word_count*WORD_WIDTH +: WORD_WIDTH]:0;

  genvar i;

  generate
    for (i = 0; i < CXSMAXPKTPERFLIT; i++) begin : gen_ptr_decode

      assign start_ptr[i] =
          cxs_ctrl[
              START_PTR_BASE + i * START_PTR_WIDTH + START_PTR_WIDTH - 1 :
              START_PTR_BASE + i * START_PTR_WIDTH
          ];

      assign start_word[i] = start_ptr[i] * ((16 * 8) / WORD_WIDTH);

      assign end_ptr[i] =
          cxs_ctrl[
              END_PTR_BASE + i * END_PTR_WIDTH + END_PTR_WIDTH - 1 :
              END_PTR_BASE + i * END_PTR_WIDTH
          ];

    end
  endgenerate

  typedef enum logic [1:0] {
    S_IDLE,
    S_CAPTURE,
    S_STREAM
  } state_e;

  state_e current_state, next_state;

  always_comb begin : next_state_logic_proc

    next_state                         = current_state;
    o_packet_formatter_flit_fifo_rd    = 1'b0;
    o_packet_formatter_async_fifo_w_en = 1'b0;

    case (current_state)

      S_IDLE: begin
        if (!i_packet_formatter_flit_fifo_empty) begin
          next_state                      = S_CAPTURE;
          o_packet_formatter_flit_fifo_rd = 1'b1;
        end

      end

      S_CAPTURE: begin
        next_state = S_STREAM;
      end

      S_STREAM: begin
        //stream mode should be smart it should use cntrl bits to detemine what words go through and  what words are dropped
        if (!i_packet_formatter_async_fifo_full) begin

          if (word_valid)
            o_packet_formatter_async_fifo_w_en = 1'b1;

          if (word_count == WORDS_PER_FLIT-1)
            next_state = S_IDLE;
        end
      end
      default:
        next_state = S_IDLE;

    endcase
  end

  always_comb begin: word_valid_proc
    word_valid = 1'b0;

    for (int j = 0; j < CXSMAXPKTPERFLIT; j++) begin
      if (start[j] &&
          end_[j] &&
          word_count >= start_word[j] &&
          word_count <= end_ptr[j]) begin
        word_valid = 1'b1;
      end
    end
  end

  always_ff @(posedge i_packet_formatter_clk or negedge i_packet_formatter_rst_n) begin: flit_capture_proc
    if (!i_packet_formatter_rst_n) begin
      current_state     <= S_IDLE;
      current_flit_data <= '0;
      cxs_ctrl          <= '0;
      word_count        <= '0;
    end
    else begin
      current_state <= next_state;

      if (current_state == S_CAPTURE) begin
        current_flit_data <= i_packet_formatter_flit_fifo_rdata[CXS_DATA_WIDTH-1:0];
        cxs_ctrl          <= i_packet_formatter_flit_fifo_rdata[FLIT_WIDTH-1 -: CXS_CNTL_WIDTH];
        word_count        <= '0;
      end
      else if (current_state == S_STREAM && !i_packet_formatter_async_fifo_full) begin
        word_count <= word_count + 1'b1;
      end
    end
  end

endmodule
