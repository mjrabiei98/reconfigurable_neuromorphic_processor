module reconfig_pe_datapath # (
    parameter WIDTH = 8,
    parameter reconfig_after_interval = 4
) (
    input wire        clk,
    input wire        rst_n,
    input wire        en_similar_neuron_counter,
    input wire        similar_neuron_counter_reset,
    input wire        similar_neuron_counter_in,
);


    Register #(.data_width(WIDTH)) pre_clk_counter_register (.clk(), .rst(), .wr_en(), .din(), .dout);


    counter #() clk_counter (.clk(), .rst(), .en(), .load(), .end_point_in(), .reached(), .count());
    counter #() interval_counter (.clk(), .rst(), .en(), .load(), .end_point_in(), .reached(), .count());
    counter #() similar_neuron_counter (.clk(), .rst(), .en(), .load(), .end_point_in(), .reached(), .count());

    /*
    module comparator #(
    parameter DATA_WIDTH = 8
) (
    input  wire [DATA_WIDTH-1:0] a,
    input  wire [DATA_WIDTH-1:0] b,
    // output wire                  eq,
    output wire                  gt_eq
    // output wire                  lt
);
    
    */


    comparer #() compare_clk_interval (.a(), .b(), .gt_eq());


endmodule