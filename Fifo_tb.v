module Fifo_tb;
    parameter DATA_WIDTH = 8;
    parameter DEPTH = 16;

    reg clk;
    reg rst;
    reg wr_en;
    reg rd_en;
    reg [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;
    wire full;
    wire empty;

    fifo #(DATA_WIDTH, DEPTH) uut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty)
    );

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        din = 0;

        // Release reset
        #10;
        rst = 0;

        // Write some data into the FIFO
        repeat (10) begin
            @(negedge clk);
            wr_en = 1;
            din = $random % 256; // Random data
            @(negedge clk);
            wr_en = 0;
        end

        // Read some data from the FIFO
        repeat (10) begin
            @(negedge clk);
            rd_en = 1;
            @(negedge clk);
            rd_en = 0;
        end

        // Finish simulation
        #20;
        $finish;
    end

    // Clock generation
    always #5 clk = ~clk;
endmodule