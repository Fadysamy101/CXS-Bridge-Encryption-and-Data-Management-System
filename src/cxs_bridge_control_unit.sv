module cxs_bridge_control_unit #(
    parameter int DATA_WIDTH = 16,
    parameter int ADDR_WIDTH = 8
) 
( input logic i_cxs_bridge_control_unit_clk,
  input logic i_cxs_bridge_control_unit_rst_n,
  input logic [DATA_WIDTH-1:0] i_cxs_bridge_control_unit_rdata
);
//instantiate the register file and write logic for write and read operations
//● System initialization and configuration registers.
//● Phase transitions (Configuration, Link-Up, Data Transmission).
//● Memory access arbitration and status reporting.
 logic[7:0] addr= i_cxs_bridge_control_unit_rdata[(DATA_WIDTH/2)-1:0];
 logic[7:0] data= i_cxs_bridge_control_unit_rdata[DATA_WIDTH-1:(DATA_WIDTH/2)];

cxs_bridge_register_file #(DATA_WIDTH, ADDR_WIDTH) reg_file_inst (
    .i_cxs_bridge_register_file_clk(i_cxs_bridge_control_unit_clk),
    .i_cxs_bridge_register_file_rst_n(i_cxs_bridge_control_unit_rst_n),
    .i_cxs_bridge_register_file_rdata(),
    .i_cxs_bridge_register_file_addr(addr),
    .i_cxs_bridge_register_file_write_en(),
    .i_cxs_bridge_register_file_read_en(),
    .o_cxs_bridge_register_file_wdata(),
    .o_cxs_bridge_read_valid()
);

typedef enum logic[1:0] {
    S_IDLE,
    S_CONFIG,
    S_LINK_UP,
    S_DATA_TRANSMISSION
} sys_state_e;
sys_state_e current_state, next_state;

always_ff @(posedge i_cxs_bridge_control_unit_clk or negedge i_cxs_bridge_control_unit_rst_n) begin: state_transition_proc
    if(!i_cxs_bridge_control_unit_rst_n) begin
        // Reset logic
        current_state <= S_IDLE;
    end else begin
        // State transition logic
        current_state <= next_state;
    end
end

always_comb begin: next_state_out_proc
    // Next state and output logic
    next_state = current_state;
    case(current_state)
        S_IDLE: begin
            // Logic for IDLE state
            next_state = S_CONFIG; // Example transition
        end
        S_CONFIG: begin
            // Logic for CONFIG state
            next_state = S_LINK_UP; // Example transition
        end
        S_LINK_UP: begin
            // Logic for LINK_UP state
            next_state = S_DATA_TRANSMISSION; // Example transition
        end
        S_DATA_TRANSMISSION: begin
            // Logic for DATA_TRANSMISSION state
            next_state = S_IDLE; // Example transition back to IDLE
        end
    endcase

end


endmodule