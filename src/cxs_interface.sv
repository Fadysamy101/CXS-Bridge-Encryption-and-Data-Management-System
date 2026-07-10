module cxs_bridge_if #(parameter ADDR_WIDTH  =8 ,parameter DATA_WIDTH =16 )(
  input  logic cxs_bridge_if_clk,
  input  logic cxs_bridge_if_rst_n,           
  input  logic [DATA_WIDTH-1:0] cxs_bridge_if_RX_Data,
  input  logic cxs_bridge_if_RX_Valid,            
  output logic [DATA_WIDTH-1:0] cxs_bridge_if_TX_Data,           
  output logic cxs_bridge_if_TX_Valid,
  output logic cxs_bridge_if_Ready            
);
  logic [7:0] rx_addr ;
  logic [7:0] rx_data ;
  assign rx_addr =  cxs_bridge_if_RX_Data[7:0];
  assign rx_data =  cxs_bridge_if_RX_Data[15:8];
  //logic [7:0] tx_addr = ;
  typedef enum logic[1:0]
  {S_IDLE,
  S_VALIDATE,
  S_PUSH,
  S_ERROR

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
always_comb begin
    cxs_bridge_if_TX_Data = 0;
    next_status=current_status;
     cxs_bridge_if_TX_Valid = 0;
  unique case(current_status)
    S_IDLE: begin
     next_status=S_IDLE;
     if(cxs_bridge_if_Ready && cxs_bridge_if_RX_Valid) begin

     end
     end  
    
    S_VALIDATE: begin 
     if(!(rx_addr ==0))
       next_status=S_PUSH;
     else begin
       next_status=S_ERROR;
       //TODO Report error somehow
     end   

    end
    S_PUSH: begin 
     cxs_bridge_if_TX_Data =cxs_bridge_if_RX_Data;
     cxs_bridge_if_TX_Valid = 1;
    end
    S_ERROR: begin
      
    end  
  endcase
end
endmodule