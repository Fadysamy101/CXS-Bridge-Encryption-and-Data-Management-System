module cxs_bridge_if #(parameter ADDR_WIDTH  =8 ,parameter DATA_WIDTH =16 )(
  input  logic cxs_bridge_if_clk,
  input  logic cxs_bridge_if_rst_n,           
  input  logic [DATA_WIDTH-1:0] cxs_bridge_if_RX_Data,
  input  logic cxs_bridge_if_RX_Valid,            
  output logic [DATA_WIDTH-1:0] cxs_bridge_if_TX_Data,           
  output logic cxs_bridge_if_TX_Valid,
  output logic cxs_bridge_if_Ready            
);
  logic [ADDR_WIDTH-1:0] rx_addr ;
  assign rx_addr =  cxs_bridge_if_RX_Data[15:8];
  assign rx_data =  cxs_bridge_if_RX_Data[7:0];
  typedef enum logic
  {S_IDLE,
   S_PUSH

  }status_e;

  status_e current_status; 
  status_e next_status; 
always_ff @(posedge cxs_bridge_if_clk or negedge cxs_bridge_if_rst_n) begin: state_transition_proc
  if(cxs_bridge_if_rst_n ==0)begin
    current_status<=S_IDLE;

  end
  else begin
    current_status<=next_status;  
    
  end  
  
end

always_comb begin : next_state_out_proc
    cxs_bridge_if_TX_Data = 0;
    next_status=current_status;
    cxs_bridge_if_TX_Valid = 0;
    cxs_bridge_if_Ready = 1;
  unique case(current_status)
    S_IDLE: begin
     next_status=S_IDLE;
     if(cxs_bridge_if_Ready && cxs_bridge_if_RX_Valid) begin
       next_status=S_PUSH;
       cxs_bridge_if_Ready = 0;
     end
     end  

    S_PUSH: begin 
     cxs_bridge_if_Ready = 0; 
     cxs_bridge_if_TX_Data =cxs_bridge_if_RX_Data;
     cxs_bridge_if_TX_Valid = 1;
    end

  endcase
end
endmodule
