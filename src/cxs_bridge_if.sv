module cxs_bridge_if #(
  parameter ADDR_WIDTH = 8,
  parameter DATA_WIDTH = 16,
  parameter TOTAL_WIDTH = ADDR_WIDTH + DATA_WIDTH
)(
  input  logic cxs_bridge_if_clk,
  input  logic cxs_bridge_if_rst_n,
  input  logic [TOTAL_WIDTH-1:0] cxs_bridge_if_RX_Data,
  input  logic cxs_bridge_if_RX_Valid,
  input  logic cxs_bridge_if_error,
  input  logic cxs_bridge_if_config_done,
  input  logic cxs_bridge_if_link_up_done,
  input  logic cxs_bridge_if_FIFO_full,

  output logic [TOTAL_WIDTH-1:0] cxs_bridge_if_TX_Data,
  output logic cxs_bridge_if_TX_Valid,
  output logic cxs_bridge_if_Ready
);

  typedef enum logic {
    S_IDLE,
    S_DATA_TRANSMISSION
  } status_e;

  status_e current_status;
  status_e next_status;

  assign cxs_bridge_if_TX_Data = cxs_bridge_if_RX_Data;

  always_ff @(posedge cxs_bridge_if_clk or negedge cxs_bridge_if_rst_n) begin : state_transition_proc
    if (!cxs_bridge_if_rst_n)
      current_status <= S_IDLE;
    else
      current_status <= next_status;
  end

  always_comb begin : next_state_out_proc
    cxs_bridge_if_Ready = !cxs_bridge_if_FIFO_full;
    cxs_bridge_if_TX_Valid = 1'b0;
    next_status = current_status;

    unique case (current_status)

      S_IDLE: begin
        if (cxs_bridge_if_RX_Valid && cxs_bridge_if_Ready) begin
          cxs_bridge_if_TX_Valid = 1'b1;
          next_status = S_DATA_TRANSMISSION;
        end
      end

      S_DATA_TRANSMISSION: begin
        if (!cxs_bridge_if_error) begin
          if (cxs_bridge_if_RX_Valid && cxs_bridge_if_Ready)
            cxs_bridge_if_TX_Valid = 1'b1;
        end
        else begin 
        // TODO: Report error through status register
        end
      end

    endcase
  end

endmodule
