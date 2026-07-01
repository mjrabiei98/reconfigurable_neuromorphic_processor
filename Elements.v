module Register #(
    parameter DATA_WIDTH = 8
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        wr_en,
    input  wire [DATA_WIDTH-1:0]  din,
    output reg  [DATA_WIDTH-1:0]  dout
);
    always @(posedge clk) begin
        if (rst) begin
            dout <= {DATA_WIDTH{1'b0}};
        end else if (wr_en && (din >= 0)) begin
            dout <= din;
        end
    end
endmodule


// module Register_initable #(
//     parameter 
//     DATA_WIDTH = 8,
//     INIT_FILE = ""
// ) (
//     input  wire        clk,
//     input  wire        rst,
//     input  wire        wr_en,
//     input  wire [DATA_WIDTH-1:0]  din,
//     output reg  [DATA_WIDTH-1:0]  dout
// );


//     initial begin

//         // Load file if provided
//         if (INIT_FILE != "") begin
//             // Use $readmemh for hex files, $readmemb for binary files
//             $readmemh(INIT_FILE, dout);
//         end
//     end

//     always @(posedge clk or posedge rst) begin
//         if (rst) begin
//             dout <= {DATA_WIDTH{1'b0}};
//         end else if (wr_en) begin
//             dout <= din;
//         end
//     end
// endmodule


module Register_initable #(
    parameter DATA_WIDTH = 8,
    parameter [DATA_WIDTH-1:0] THRESHOLD_VALUE = 8
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] din,
    output reg  [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] init_mem = THRESHOLD_VALUE;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
                dout <= THRESHOLD_VALUE;
        end
        else if (wr_en) begin
            dout <= din;
        end
    end

endmodule

module mux2to1 #(parameter DATA_WIDTH = 8) (
    input  wire [DATA_WIDTH-1:0] in0,
    input  wire [DATA_WIDTH-1:0] in1,
    input  wire                  sel,
    output wire  [DATA_WIDTH-1:0] out
);
    assign out = sel ? in1 : in0;
endmodule

module not_each_bit #(parameter DATA_WIDTH = 8)(
    input wire [DATA_WIDTH-1:0] in,
    output wire [DATA_WIDTH-1:0] out
);
    assign out = ~in;
endmodule

module mux4to1 #(
    parameter DATA_WIDTH = 8
) (
    input  wire [DATA_WIDTH-1:0] in0,
    input  wire [DATA_WIDTH-1:0] in1,
    input  wire [DATA_WIDTH-1:0] in2,
    input  wire [DATA_WIDTH-1:0] in3,
    input  wire [1:0]            sel,
    output reg  [DATA_WIDTH-1:0] out
);
    always @(*) begin
        case (sel)
            2'b00: out = in0;
            2'b01: out = in1;
            2'b10: out = in2;
            2'b11: out = in3;
            default: out = {DATA_WIDTH{1'b0}};
        endcase
    end
endmodule

module comparator #(
    parameter DATA_WIDTH = 8
) (
    input  wire [DATA_WIDTH-1:0] a,
    input  wire [DATA_WIDTH-1:0] b,
    // output wire                  eq,
    output wire                  gt_eq
    // output wire                  lt
);
    // assign eq = (a == b);
    assign gt_eq = (a >= b);
    // assign lt = (a < b);
endmodule



module counter #(
    parameter COUNT_WIDTH = 8
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  en,
    input  wire                  load,
    input  wire [COUNT_WIDTH-1:0] end_point_in,
    output wire                  reached,
    output reg  [COUNT_WIDTH-1:0] count
);

    reg [COUNT_WIDTH-1:0] end_point;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= {COUNT_WIDTH{1'b0}};
            end_point <= {{(COUNT_WIDTH-3){1'b0}}, 3'b100};
        end else if (load) begin
                
            end_point <= end_point_in;
            count <= {COUNT_WIDTH{1'b0}};

        end else if (en && (count != end_point)) begin
            count <= count + 1;
        end else if (count == end_point) begin
            count <= {COUNT_WIDTH{1'b0}};
        end
    end
    assign reached = (count == end_point) ? 1'b1 : 1'b0;

endmodule


module Adder #(parameter DATA_WIDTH = 8) (
    input  wire [DATA_WIDTH-1:0] a,
    input  wire [DATA_WIDTH-1:0] b,
    input  wire cin,
    output wire [DATA_WIDTH-1:0] sum
);
    assign sum = a + b + cin;
endmodule


module shifter #(
    parameter number_right_shift = 2,
    parameter DATA_WIDTH = 8
)
(
    input [DATA_WIDTH-1:0] din,
    output [DATA_WIDTH-1:0] dout
);
    assign dout = din >> number_right_shift;
endmodule


module fifo #(parameter DATA_WIDTH = 8, parameter DEPTH = 16) (
    input wire clk,
    input wire rst,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    output reg full,
    output reg empty
);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    localparam PTR_W = $clog2(DEPTH);
    reg [PTR_W-1:0] wr_ptr, rd_ptr;
    reg [DEPTH:0] count;

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            full <= 0;
            empty <= 1;
            dout <= {DATA_WIDTH{1'b0}};
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= {DATA_WIDTH{1'b0}};
        end else begin
            // Write operation
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= (wr_ptr + 1) % DEPTH;
                count <= count + 1;
                full <= (count + 1 == DEPTH);
                empty <= (count + 1 == 0);
            end

            // Read operation
            if (rd_en && !empty) begin
                dout <= mem[rd_ptr];
                rd_ptr <= (rd_ptr + 1) % DEPTH;
                count <= count - 1;
                full <= (count - 1 == DEPTH);
                empty <= (count - 1 == 0);
            end

            // Update full and empty flags
            // full <= (count - 1 == DEPTH);
            //     empty <= (count - 1 == 0);
            
        end
    end
endmodule

module Memory #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8,
    parameter INIT_FILE  = ""   // e.g. "mem_init.hex" (leave empty to skip)
) (
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  addr,
    input  wire [DATA_WIDTH-1:0]  din,
    output reg  [DATA_WIDTH-1:0]  dout
);

    localparam DEPTH = 1 << ADDR_WIDTH;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // ------------------------------------------------------------
    // Memory initialization from file (SIM + many FPGA flows)
    // ------------------------------------------------------------
    integer i;
    initial begin
        // Optional: default contents (useful for simulation determinism)
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = {DATA_WIDTH{1'b0}};

        // Load file if provided
        if (INIT_FILE != "") begin
            // Use $readmemh for hex files, $readmemb for binary files
            $readmemh(INIT_FILE, mem);
        end
    end

    // ------------------------------------------------------------
    // Synchronous read / write (1-port, R/W mutually exclusive)
    // ------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= {DATA_WIDTH{1'b0}};
        end else begin
            if (wr_en) begin
                mem[addr] <= din;
            end else begin
                dout <= mem[addr];
            end
        end
    end

endmodule



module reconfig_packet_generator #(
    parameter neuron_address_size = 10
) (
    input wire [neuron_address_size-1:0] neuron_list_memory_dout,
    input wire change_value,
    output wire [20:0] reconfig_packet
);
    assign reconfig_packet = {1'b1, 4'b0000, 4'b0000, neuron_list_memory_dout, 1'b0, change_value};

endmodule


module counter_with_limit #(
    parameter COUNT_WIDTH = 8,
    parameter LIMIT = 8
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  en,
    output wire                  reached,
    output reg  [COUNT_WIDTH-1:0] count
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= {COUNT_WIDTH{1'b0}};
        end else if (en && (count != LIMIT)) begin
            count <= count + 1;
        end else if (count == LIMIT) begin
            count <= {COUNT_WIDTH{1'b0}};
        end
    end
    assign reached = (count == LIMIT) ? 1'b1 : 1'b0;

endmodule