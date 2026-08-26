
module control_unit #(
  parameter int ADDR_WIDTH = 16,   // CDM / ATU address bus (spec 9, 10)
  parameter int DATA_WIDTH = 16    // payload width handed to the encryption block
)(
  input  logic                        i_control_unit_clk,
  input  logic                        i_control_unit_rst_n,

  // Async FIFO. The FIFO memory is read-through: i_control_unit_fifo_data_in is already
  // valid whenever i_control_unit_fifo_empty is low, and o_control_unit_fifo_en pops that same word.
  input  logic                        i_control_unit_fifo_empty,
  output logic                        o_control_unit_fifo_en,
  input  logic [(2*DATA_WIDTH)-1:0]   i_control_unit_fifo_data_in,

  // CDM write path
  output logic                        o_control_unit_direct_cdm_write,
  output logic                        o_control_unit_w_en,
  output logic [ADDR_WIDTH-1:0]       o_control_unit_addr_out,
  output logic [DATA_WIDTH-1:0]       o_control_unit_data_out,
  // Configuration word for the direct (encryption-bypass) CDM write.
  // A device entry is {END_ADDR, START_ADDR} = 32 bits, so it cannot be
  // carried on the 16-bit o_control_unit_data_out that feeds the encryption block.
  output logic [(2*DATA_WIDTH)-1:0]   o_control_unit_cfg_data_out,

  // Configured device count, tapped from the CDM configuration register
  input  logic [7:0]                  i_control_unit_dev_count,

  output logic                        o_control_unit_error_valid,
  output logic [1:0]                  o_control_unit_error
);

  // Words per TLP: header + 3 payloads (spec 7.2)
  localparam int TLP_WORDS  = 4;
  localparam int WCNT_WIDTH = $clog2(TLP_WORDS);

  // CDM map (spec 10.1)
  localparam logic [ADDR_WIDTH-1:0] CFG_ADDR = ADDR_WIDTH'('h0000);
  localparam logic [ADDR_WIDTH-1:0] DEV_BASE = ADDR_WIDTH'('h0001);

  // Header SYS_STATE field = packet type (spec 5 register file / 6.2.1)
  localparam logic [1:0] PKT_IDLE     = 2'b00;
  localparam logic [1:0] PKT_CONFIG   = 2'b01;
  localparam logic [1:0] PKT_LINKUP   = 2'b10;
  localparam logic [1:0] PKT_TRANSFER = 2'b11;

  localparam logic [3:0] ENC_EVEN = 4'h0;
  localparam logic [3:0] ENC_ODD  = 4'h1;

  localparam logic [1:0] ERR_INVALID_HEADER_PKT = 2'b00;
  localparam logic [1:0] ERR_INVALID_ENC        = 2'b01;
  localparam logic [1:0] ERR_INVALID_STATE      = 2'b10;

  typedef enum logic [2:0] {
    S_IDLE     = 3'b000,
    S_CFG_HDR  = 3'b001,
    S_LINK_UP  = 3'b011,
    S_DATA_HDR = 3'b111,
    S_ERROR    = 3'b101
  } state_e;

  state_e state, next_state;

  // Header decode of the word currently presented by the FIFO
  wire       word_valid     = !i_control_unit_fifo_empty;
  wire [1:0] hdr_pkt_type   = i_control_unit_fifo_data_in[1:0];
  wire [3:0] hdr_enc_mode   = i_control_unit_fifo_data_in[7:4];
  wire       enc_mode_valid = (hdr_enc_mode == ENC_EVEN) || (hdr_enc_mode == ENC_ODD);

  // Transfer TLP payload word: ADDR [31:16], DATA [15:0] (spec 6.3)
  wire [ADDR_WIDTH-1:0] payload_addr = i_control_unit_fifo_data_in[(2*DATA_WIDTH)-1 -: ADDR_WIDTH];
  wire [DATA_WIDTH-1:0] payload_data = i_control_unit_fifo_data_in[DATA_WIDTH-1:0];

  // Placeholder: header validation will eventually be answered by the target
  // device. Until then every Link-Up header is accepted.
  wire header_packet_valid = 1'b1;

  logic [WCNT_WIDTH-1:0] tlp_word_counter;          // spec 5.2
  logic [8:0]            tlp_config_counter;        // spec 5.3
  logic                  cfg_hdr_written;           // global register already at 0x0000
  logic                  linkup_frame_done;         // Link-Up header consumed
  logic [1:0]            err_code;

  wire is_header = (tlp_word_counter == '0);

  // '>=' rather than '==': the words padding out the last configuration frame
  // are written too, pushing the counter past i_control_unit_dev_count.
  wire addresses_finished = (tlp_config_counter >= {1'b0, i_control_unit_dev_count});

  logic cfg_hdr_latch, cfg_cnt_inc, linkup_hdr_latch;
  logic err_set;
  logic [1:0] err_code_nxt;

  assign o_control_unit_error = err_code;

  always_comb begin: next_state_logic_proc
    next_state                      = state;

    o_control_unit_fifo_en          = 1'b0;
    o_control_unit_w_en             = 1'b0;
    o_control_unit_direct_cdm_write = 1'b0;
    o_control_unit_addr_out         = '0;
    o_control_unit_data_out         = '0;
    o_control_unit_cfg_data_out     = '0;
    o_control_unit_error_valid      = 1'b0;

    cfg_hdr_latch                   = 1'b0;
    cfg_cnt_inc                     = 1'b0;
    linkup_hdr_latch                = 1'b0;
    err_set                         = 1'b0;
    err_code_nxt                    = err_code;

    case (state)

      // Wait for a Configuration TLP header. The word is only peeked
      // here; S_CFG_HDR consumes it.
      S_IDLE: begin
        if (word_valid) begin
          if (hdr_pkt_type == PKT_CONFIG)
            next_state = S_CFG_HDR;
          else
            o_control_unit_fifo_en = 1'b1;   // drop anything that is not a config header
            //TODO go to o_control_unit_error
        end
      end

      S_CFG_HDR: begin
        if (word_valid) begin
          if (is_header) begin
            // First header of the phase: it carries the global
            // configuration register. addresses_finished must not be
            // consulted yet - the CDM still holds its reset value.
            if (!cfg_hdr_written) begin
              o_control_unit_fifo_en = 1'b1;
              if (!enc_mode_valid) begin
                err_set      = 1'b1;
                err_code_nxt = ERR_INVALID_ENC;
                next_state   = S_ERROR;
              end
              else begin
                o_control_unit_direct_cdm_write = 1'b1;
                o_control_unit_w_en             = 1'b1;
                o_control_unit_addr_out         = CFG_ADDR;
                o_control_unit_cfg_data_out     = i_control_unit_fifo_data_in;
                cfg_hdr_latch    = 1'b1;
              end
            end
            // All device entries written: only a Link-Up header may
            // follow. Peek it, S_LINK_UP consumes it.
            else if (addresses_finished) begin
              if (hdr_pkt_type == PKT_LINKUP) begin
                next_state = S_LINK_UP;
              end
              else begin
                o_control_unit_fifo_en      = 1'b1;
                err_set      = 1'b1;
                err_code_nxt = ERR_INVALID_STATE;
                next_state   = S_ERROR;
              end
            end
            // Still filling device entries: the configuration must
            // continue in another Configuration TLP.
            else begin
              o_control_unit_fifo_en = 1'b1;
              if (hdr_pkt_type != PKT_CONFIG) begin
                err_set      = 1'b1;
                err_code_nxt = ERR_INVALID_STATE;
                next_state   = S_ERROR;
              end
            end
          end
          // Device configuration entry -> CDM 0x0001 upwards
          else begin
            o_control_unit_fifo_en          = 1'b1;
            o_control_unit_direct_cdm_write = 1'b1;
            o_control_unit_w_en             = 1'b1;
            o_control_unit_addr_out         = DEV_BASE + ADDR_WIDTH'(tlp_config_counter);
            o_control_unit_cfg_data_out     = i_control_unit_fifo_data_in;
            cfg_cnt_inc      = 1'b1;
          end
        end
      end

      // The Link-Up packet is consumed whole, like any other TLP, before
      // data transfer starts. word_valid on a header is header_valid_en.
      S_LINK_UP: begin
        if (word_valid) begin
          if (is_header && !linkup_frame_done) begin
            o_control_unit_fifo_en = 1'b1;
            if (header_packet_valid) begin
              linkup_hdr_latch = 1'b1;
            end
            else begin
              err_set      = 1'b1;
              err_code_nxt = ERR_INVALID_HEADER_PKT;
              next_state   = S_ERROR;
            end
          end
          // Frame complete: peek the next header, S_DATA_HDR takes it.
          else if (is_header) begin
            next_state = S_DATA_HDR;
          end
          // Remaining words of the Link-Up packet are payload words
          // like any other: address to the ATU, data to encryption
          // and parity.
          else begin
            o_control_unit_fifo_en  = 1'b1;
            o_control_unit_w_en     = 1'b1;
            o_control_unit_addr_out = payload_addr;
            o_control_unit_data_out = payload_data;
          end
        end
      end

      S_DATA_HDR: begin
        if (word_valid) begin
          if (is_header) begin
            o_control_unit_fifo_en = 1'b1;
            case (hdr_pkt_type)
              PKT_TRANSFER: ;                      // payloads follow
              PKT_LINKUP: begin
                o_control_unit_fifo_en    = 1'b0;               // peek, S_LINK_UP takes it
                next_state = S_LINK_UP;
              end
              default: begin                       // Idle / Config
                err_set      = 1'b1;
                err_code_nxt = ERR_INVALID_STATE;
                next_state   = S_ERROR;
              end
            endcase
          end
          // Payload word: address to the ATU, data to encryption + parity
          else begin
            o_control_unit_fifo_en  = 1'b1;
            o_control_unit_w_en     = 1'b1;
            o_control_unit_addr_out = payload_addr;
            o_control_unit_data_out = payload_data;
          end
        end
      end

      // Single-cycle report to the Packet Encoder, which edge-detects
      // o_control_unit_error_valid; that pulse is the error_reported handshake.
      S_ERROR: begin
        o_control_unit_error_valid = 1'b1;
        next_state  = S_IDLE;
      end

      default: next_state = S_IDLE;

    endcase
  end

  always_ff @(posedge i_control_unit_clk or negedge i_control_unit_rst_n) begin: state_proc
    if (!i_control_unit_rst_n) begin
      state              <= S_IDLE;
      tlp_word_counter   <= '0;
      tlp_config_counter <= '0;
      cfg_hdr_written    <= 1'b0;
      linkup_frame_done  <= 1'b0;
      err_code           <= '0;
    end
    else begin
      state <= next_state;

      if (err_set)
        err_code <= err_code_nxt;

      // Frame position. Held at 0 in Idle so the words dropped there
      // cannot pull the frame out of alignment.
      if (state == S_IDLE)
        tlp_word_counter <= '0;
      else if (o_control_unit_fifo_en)
        tlp_word_counter <= (tlp_word_counter == WCNT_WIDTH'(TLP_WORDS-1)) ?
                            '0 : tlp_word_counter + WCNT_WIDTH'(1);

      if (next_state == S_IDLE) begin
        cfg_hdr_written    <= 1'b0;
        tlp_config_counter <= '0;
      end
      else if (cfg_hdr_latch) begin
        cfg_hdr_written    <= 1'b1;
        tlp_config_counter <= '0;
      end
      else if (cfg_cnt_inc) begin
        tlp_config_counter <= tlp_config_counter + 9'd1;
      end

      // Cleared on every exit from Link-Up, so a Link-Up packet arriving
      // later out of the data phase is consumed whole again.
      if (next_state != S_LINK_UP)
        linkup_frame_done <= 1'b0;
      else if (linkup_hdr_latch)
        linkup_frame_done <= 1'b1;
    end
  end

endmodule
