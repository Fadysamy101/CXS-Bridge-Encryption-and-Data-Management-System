module cxs_bridge_control_unit #(
    parameter int DATA_WIDTH = 16,
    parameter int ADDR_WIDTH = 8,
    parameter int WORD_WIDTH = ADDR_WIDTH + DATA_WIDTH  
)
(
    input  logic i_cxs_bridge_control_unit_clk,
    input  logic i_cxs_bridge_control_unit_rst_n,

    input  logic [WORD_WIDTH-1:0] i_cxs_bridge_control_unit_wdata,
    input  logic i_cxs_bridge_control_unit_packet_available,
    input  logic i_cxs_bridge_control_unit_fifo_empty,


    input  logic i_cxs_bridge_control_unit_header_valid,


    output logic o_cxs_bridge_control_unit_config_done,
    output logic o_cxs_bridge_control_unit_link_up_done,
    output logic o_cxs_bridge_control_unit_error_valid,
    output logic [2:0] o_cxs_bridge_control_unit_error_code
);
   
    localparam logic [2:0] ERR_NONE            = 3'b000;
    localparam logic [2:0] ERR_INVALID_ADDR    = 3'b001;
    localparam logic [2:0] ERR_INVALID_ENC     = 3'b010;
    localparam logic [2:0] ERR_PARITY_MISMATCH = 3'b011; 
    localparam logic [2:0] ERR_INVALID_STATE   = 3'b100;

    typedef enum logic [1:0] {
        S_IDLE,
        S_CONFIG,
        S_LINK_UP,
        S_DATA_TRANSMISSION
    } sys_state_e;

    sys_state_e current_state, next_state;

    //Data fields for reg file addresses
    logic [7:0]  dev_count;   // [15:8]
    logic [3:0]  enc_mode;    // [7:4]
    logic [1:0]  parity_mode; // [3:2]
    logic [1:0]  sys_state;   // [1:0]

    logic [7:0] device_start;
    logic [7:0] device_end;

    logic reg_write_en;
    logic reg_read_en;
    logic [DATA_WIDTH-1:0] reg_rdata;
    logic reg_read_valid;
    logic [DATA_WIDTH-1:0] reg_wdata;
    logic [7:0] devices_configured;
    logic [ADDR_WIDTH-1:0] reg_addr;

    logic addresses_allocated;
    logic transmission_done;
    logic [1:0] transmission_counter;

    assign reg_wdata = i_cxs_bridge_control_unit_wdata[DATA_WIDTH-1:0];
    assign reg_addr = i_cxs_bridge_control_unit_wdata[WORD_WIDTH-1:DATA_WIDTH];

    assign addresses_allocated = (devices_configured == dev_count) && (dev_count != '0);

    assign transmission_done = transmission_counter == 3;
    //determning if all addreses are allocated 
    assign device_start = i_cxs_bridge_control_unit_wdata[(DATA_WIDTH/2)-1:0];
    assign device_end = i_cxs_bridge_control_unit_wdata[DATA_WIDTH-1:DATA_WIDTH/2];


    always_ff @(posedge i_cxs_bridge_control_unit_clk or negedge i_cxs_bridge_control_unit_rst_n) begin
    if (!i_cxs_bridge_control_unit_rst_n) begin
        dev_count   <= '0;
        enc_mode    <= '0;
        parity_mode <= '0;
        sys_state   <= '0;
    end
    else if (reg_addr == 0 && current_state==S_CONFIG) begin
        dev_count   <= i_cxs_bridge_control_unit_wdata[15:8];
        enc_mode    <= i_cxs_bridge_control_unit_wdata[7:4];
        parity_mode <= i_cxs_bridge_control_unit_wdata[3:2];
        sys_state   <= i_cxs_bridge_control_unit_wdata[1:0];
    end
    end




    cxs_bridge_register_file 
    #(
        .DATA_WIDTH (DATA_WIDTH ),
        .ADDR_WIDTH (ADDR_WIDTH )
    )
    u_cxs_bridge_register_file(
        .i_cxs_bridge_register_file_clk      (i_cxs_bridge_control_unit_clk      ),
        .i_cxs_bridge_register_file_rst_n    (i_cxs_bridge_control_unit_rst_n    ),
        .i_cxs_bridge_register_file_wdata    (reg_wdata   ),
        .i_cxs_bridge_register_file_addr     (reg_addr    ),
        .i_cxs_bridge_register_file_write_en (reg_write_en ),
        .i_cxs_bridge_register_file_read_en  (reg_read_en  ),
        .o_cxs_bridge_register_file_rdata    (reg_rdata   ),
        .o_cxs_bridge_read_valid             (reg_read_valid) 
    );
    
   



    always_ff @(posedge i_cxs_bridge_control_unit_clk or negedge i_cxs_bridge_control_unit_rst_n) begin
        if (!i_cxs_bridge_control_unit_rst_n) begin
            current_state        <= S_IDLE;

        end else begin
            current_state        <= next_state;  
        end
    end


    always_ff @(posedge i_cxs_bridge_control_unit_clk or negedge i_cxs_bridge_control_unit_rst_n) begin
    if (!i_cxs_bridge_control_unit_rst_n) begin
        devices_configured <= '0;
    end else if (current_state == S_CONFIG) begin
        if (reg_addr != 8'h00 && (device_start != '0) && (device_end != '0)) begin
        devices_configured <= devices_configured + 1'b1;
        end
    end else begin
        devices_configured <= '0; // reset counter on leaving Config, ready for next session
    end
    end


  //TODO Header Validation logic

  



  //TODO Header Validation logic

  //TODO determine what is pupose of sys_state in reg file


    always_comb begin
        next_state = current_state;
     
        o_cxs_bridge_control_unit_config_done  = 1'b0;
        o_cxs_bridge_control_unit_link_up_done = 1'b0;
        o_cxs_bridge_control_unit_error_valid  = 1'b0;
        o_cxs_bridge_control_unit_error_code   = ERR_NONE;
        transmission_counter = 2'b00;
        reg_write_en = 1'b0;

        unique case (current_state)

            S_IDLE: begin
                if (i_cxs_bridge_control_unit_packet_available && !i_cxs_bridge_control_unit_fifo_empty) begin
                    next_state = S_CONFIG;
                    reg_write_en = 1'b1;
                end
            end

            S_CONFIG: begin

                if((enc_mode>1))begin
                    o_cxs_bridge_control_unit_error_valid = 1'b1;
                    o_cxs_bridge_control_unit_error_code  = ERR_INVALID_ENC;    
                end
                else
                if (i_cxs_bridge_control_unit_packet_available && !i_cxs_bridge_control_unit_fifo_empty) begin
                    reg_write_en = 1'b1;
                end



                if (addresses_allocated) begin
                    next_state = S_LINK_UP;
                    o_cxs_bridge_control_unit_config_done = 1'b1;
                end
            end
        

            S_LINK_UP: begin
                if (!i_cxs_bridge_control_unit_header_valid) begin
              
                    next_state = S_LINK_UP;
                end else if (i_cxs_bridge_control_unit_header_valid && !i_cxs_bridge_control_unit_fifo_empty) begin
                    next_state = S_DATA_TRANSMISSION;
                    o_cxs_bridge_control_unit_link_up_done = 1'b1;
                end
            end

            S_DATA_TRANSMISSION: begin
                if (i_cxs_bridge_control_unit_packet_available) begin
                    transmission_counter = transmission_counter + 1'b1;
                end    

                if (transmission_done) begin
                    next_state = S_LINK_UP; 
                end
            end

        endcase
    end

endmodule