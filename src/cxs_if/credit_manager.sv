
module credit_manager #(
    parameter int DEPTH = 16
)(
    input  logic                  rst_n,           
    input  logic                  clk,             

    input  logic                  flit_fifo_wr,    
    input  logic                  flit_fifo_rd,
    input  logic                  flit_fifo_empty,    
    input  logic                  flit_fifo_full,    

    output logic                  cxs_rx_crdgnt   
);

    localparam int CNT_WIDTH = $clog2(DEPTH) + 1;   
    logic [$clog2(DEPTH):0] credit_counter;
    


    
    wire grant = (|credit_counter); //as long there is at least one credit, grant credits.

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            credit_counter <= CNT_WIDTH'(DEPTH);
          
            cxs_rx_crdgnt  <= 1'b0;
        end
        else begin
            // counter operation. A simultaneous read and write
            // leaves the occupancy - and therefore the counter - unchanged.
            if(flit_fifo_rd && !flit_fifo_empty && !flit_fifo_wr) begin
                credit_counter <= credit_counter + 1'b1;
            end

            else if(flit_fifo_wr && !flit_fifo_full && !flit_fifo_rd) begin
                credit_counter <= credit_counter - 1'b1;
            end
  
          

            
            cxs_rx_crdgnt  <= grant;
            
        end
    end

endmodule
