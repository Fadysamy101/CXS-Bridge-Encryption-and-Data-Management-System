`timescale 1ns/1ps

module packet_formatter_tb;

localparam int CXS_DATA_WIDTH       = 256;
localparam int CXS_CNTL_WIDTH       = 14;
localparam int WORD_WIDTH           = 32;
localparam int CXSMAXPKTPERFLIT     = 2;
localparam int FLIT_WIDTH           = CXS_DATA_WIDTH + CXS_CNTL_WIDTH;

localparam int WORDS_PER_FLIT       = CXS_DATA_WIDTH / WORD_WIDTH;

logic                     clk;
logic                     rst_n;

logic                     flit_fifo_empty;
logic [FLIT_WIDTH-1:0]    flit_fifo_rdata;
logic                     async_fifo_full;

logic                     flit_fifo_rd;
logic                     async_fifo_w_en;
logic [WORD_WIDTH-1:0]    async_fifo_w_data;


packet_formatter #(
    .CXS_DATA_WIDTH      (CXS_DATA_WIDTH),
    .CXS_CNTL_WIDTH      (CXS_CNTL_WIDTH),
    .WORD_WIDTH          (WORD_WIDTH),
    .CXSMAXPKTPERFLIT    (CXSMAXPKTPERFLIT),
    .FLIT_WIDTH           (FLIT_WIDTH)
) dut (
    .rst_n              (rst_n),
    .clk                (clk),

    .flit_fifo_empty    (flit_fifo_empty),
    .flit_fifo_rdata    (flit_fifo_rdata),
    .async_fifo_full    (async_fifo_full),

    .flit_fifo_rd       (flit_fifo_rd),
    .async_fifo_w_en    (async_fifo_w_en),
    .async_fifo_w_data  (async_fifo_w_data)
);


initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end


initial begin
    rst_n           = 1'b0;
    flit_fifo_empty = 1'b1;
    flit_fifo_rdata = '0;
    async_fifo_full = 1'b0;

    repeat (2)
        @(posedge clk);

    rst_n = 1'b1;

    repeat (2)
        @(posedge clk);


    // ============================================================
    // TEST 1
    // One packet occupying words 0,1,2
    //
    // START0    = 1
    // START0PTR = 0
    // END0      = 1
    // END0PTR   = 2
    //
    // CXSCNTL:
    //   [13:11] END1PTR   = 000
    //   [10:8]  END0PTR   = 010
    //   [7:6]   ENDERROR  = 00
    //   [5:4]   END       = 01
    //   [3]     START1PTR = 0
    //   [2]     START0PTR = 0
    //   [1:0]   START     = 01
    //
    // CXSCNTL = 000_010_00_01_0_0_01
    //
    // Expected data words:
    //   word 0
    //   word 1
    //   word 2
    // ============================================================

    send_flit(
        14'b000_010_00_01_0_0_01,
        {
            32'hAAAA_AAAA,
            32'h7777_7777,
            32'h6666_6666,
            32'h5555_5555,
            32'h4444_4444,
            32'h3333_3333,
            32'h2222_2222,
            32'h1111_1111
        }
    );


    repeat (2)
        @(posedge clk);


    // ============================================================
    // TEST 2
    // One packet occupying words 4,5,6,7
    //
    // START0    = 1
    // START0PTR = 1  -> word 4
    // END0      = 1
    // END0PTR   = 7
    //
    // CXSCNTL:
    //   [13:11] END1PTR   = 000
    //   [10:8]  END0PTR   = 111
    //   [7:6]   ENDERROR  = 00
    //   [5:4]   END       = 01
    //   [3]     START1PTR = 0
    //   [2]     START0PTR = 1
    //   [1:0]   START     = 01
    //
    // CXSCNTL = 000_111_00_01_0_1_01
    //
    // Expected data words:
    //   word 4
    //   word 5
    //   word 6
    //   word 7
    // ============================================================

    send_flit(
        14'b000_111_00_01_0_1_01,
        {
            32'hBBBB_BBBB,
            32'hAAAA_AAAA,
            32'h9999_9999,
            32'h8888_8888,
            32'h7777_7777,
            32'h6666_6666,
            32'h5555_5555,
            32'h4444_4444
        }
    );


    repeat (2)
        @(posedge clk);


    // ============================================================
    // TEST 3
    // Two packets in one flit
    //
    // Packet 0:
    //   START0    = 1
    //   START0PTR = 0
    //   END0      = 1
    //   END0PTR   = 2
    //
    // Packet 1:
    //   START1    = 1
    //   START1PTR = 1 -> word 4
    //   END1      = 1
    //   END1PTR   = 7
    //
    // CXSCNTL:
    //   [13:11] END1PTR   = 111
    //   [10:8]  END0PTR   = 010
    //   [7:6]   ENDERROR  = 00
    //   [5:4]   END       = 11
    //   [3]     START1PTR = 1
    //   [2]     START0PTR = 0
    //   [1:0]   START     = 11
    //
    // CXSCNTL = 111_010_00_11_1_0_11
    //
    // Expected:
    //   words 0,1,2,4,5,6,7
    //
    // Word 3 should be skipped.
    // ============================================================

    send_flit(
        14'b111_010_00_11_1_0_11,
        {
            32'hDDDD_DDDD,
            32'hCCCC_CCCC,
            32'hBBBB_BBBB,
            32'hAAAA_AAAA,
            32'h7777_7777,
            32'h6666_6666,
            32'h5555_5555,
            32'h4444_4444
        }
    );


    repeat (2)
        @(posedge clk);


    // ============================================================
    // TEST 4
    // Packet starts at word 0 and ends at word 7.
    //
    // START0    = 1
    // START0PTR = 0
    // END0      = 1
    // END0PTR   = 7
    //
    // CXSCNTL:
    //   [13:11] END1PTR   = 000
    //   [10:8]  END0PTR   = 111
    //   [7:6]   ENDERROR  = 00
    //   [5:4]   END       = 01
    //   [3]     START1PTR = 0
    //   [2]     START0PTR = 0
    //   [1:0]   START     = 01
    //
    // CXSCNTL = 000_111_00_01_0_0_01
    //
    // Expected:
    //   all 8 words
    // ============================================================

    send_flit(
        14'b000_111_00_01_0_0_01,
        {
            32'h8888_8888,
            32'h7777_7777,
            32'h6666_6666,
            32'h5555_5555,
            32'h4444_4444,
            32'h3333_3333,
            32'h2222_2222,
            32'h1111_1111
        }
    );


    repeat (2)
        @(posedge clk);


    // ============================================================
    // TEST 5
    // async FIFO backpressure.
    //
    // Packet configuration is the same as TEST 1:
    //   START0    = 1
    //   START0PTR = 0
    //   END0      = 1
    //   END0PTR   = 2
    //
    // CXSCNTL = 000_010_00_01_0_0_01
    //
    // Hold async_fifo_full high while streaming.
    // DUT should stop advancing word_count.
    // ============================================================

    async_fifo_full = 1'b1;
    send_flit(
        14'b000_010_00_01_0_0_01,
        {
            32'hFEDC_BA98,
            32'h7654_3210,
            32'hAAAA_0004,
            32'hAAAA_0003,
            32'hAAAA_0002,
            32'hAAAA_0001,
            32'hAAAA_0000,
            32'h1234_5678
        }
    );

    repeat (8)
        @(posedge clk);

   
    async_fifo_full = 1'b0;

    repeat (10)
        @(posedge clk);


    // ============================================================
    // End simulation
    // ============================================================

    $finish;
end


task automatic send_flit(
    input logic [CXS_CNTL_WIDTH-1:0] ctrl,
    input logic [CXS_DATA_WIDTH-1:0] data
);
    begin
        // Present a valid flit to the FIFO.
        flit_fifo_empty = 1'b0;
        flit_fifo_rdata = {ctrl, data};

        // Wait until DUT requests the flit.
        @(posedge clk);
        wait (flit_fifo_rd);

        // Keep rdata stable through the capture cycle.
        @(posedge clk);

        // Remove FIFO contents after capture.
        flit_fifo_empty = 1'b1;
        flit_fifo_rdata = '0;

        // Allow the DUT to stream the flit.
        repeat (WORDS_PER_FLIT + 2)
            @(posedge clk);
    end
endtask

endmodule
