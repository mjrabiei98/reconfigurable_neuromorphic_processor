module reconfig_pe_datapath # (
    parameter WIDTH = 32,
    parameter reconfig_after_interval = 32'd10,
    parameter neuron_list_size = 10'd5,
    parameter all_dest = 4'b1111,
    parameter neuron_address_size = 10,
    parameter Similar_neuron_INIT_FILE = ""
) (
    input wire        clk,
    input wire        rst,
    input wire        similar_neuron_counter_en,
    input wire        similar_neuron_counter_rst,
    // input wire        similar_neuron_counter_load,
    input wire        clk_counter_en,
    input wire        clk_counter_rst,
    input wire        clk_counter_load,
    input wire        interval_counter_en,
    input wire        interval_counter_rst,
    // input wire        interval_counter_load,
    input wire        pre_clk_register_wr_en,
    input wire        pre_clk_register_rst,
    input wire        change_value,

    output wire       similar_neuron_counter_reached,
    output wire       clk_counter_reached,
    output wire       interval_counter_reached,
    output wire       [20:0] reconfig_packet,
    output wire       compare_out

);

    wire [9:0] similar_neuron_counter_count;
    wire [31:0] clk_counter_count;
    wire [31:0] interval_counter_count;
    wire [31:0] pre_clk_counter_register_dout;
    wire gt_eq; // output of comparator, 1 if clk_counter_count >= interval_counter_count
    wire [9:0] neuron_address; // address of the neuron to be reconfigured



    counter #(.COUNT_WIDTH(32)) clk_counter (
        .clk(clk),
        .rst(clk_counter_rst), 
        .en(clk_counter_en), 
        .load(clk_counter_load), 
        .end_point_in(), 
        .reached(clk_counter_reached), 
        .count(clk_counter_count)
    );



    // counter #(.COUNT_WIDTH(32)) interval_counter (
    //     .clk(clk), 
    //     .rst(interval_counter_rst), 
    //     .en(interval_counter_en), 
    //     .load(interval_counter_load), 
    //     .end_point_in(reconfig_after_interval), 
    //     .reached(interval_counter_reached), 
    //     .count(interval_counter_count)
    // );

    counter_with_limit #(.COUNT_WIDTH(32), .LIMIT(reconfig_after_interval)) interval_counter (
        .clk(clk), 
        .rst(interval_counter_rst), 
        .en(interval_counter_en), 
        .count(interval_counter_count), 
        .reached(interval_counter_reached)
    );


    // counter #(.COUNT_WIDTH(10)) similar_neuron_counter (
    //     .clk(clk), 
    //     .rst(similar_neuron_counter_rst), 
    //     .en(similar_neuron_counter_en), 
    //     .load(similar_neuron_counter_load), 
    //     .end_point_in(neuron_list_size), // end point is not set
    //     .reached(similar_neuron_counter_reached), 
    //     .count(similar_neuron_counter_count)
    // );


    counter_with_limit #(.COUNT_WIDTH(10), .LIMIT(neuron_list_size)) similar_neuron_counter (
        .clk(clk), 
        .rst(similar_neuron_counter_rst), 
        .en(similar_neuron_counter_en), 
        .count(similar_neuron_counter_count), 
        .reached(similar_neuron_counter_reached)
    );


    comparator #(.DATA_WIDTH(32)) compare_clk_interval (
        .a(clk_counter_count), 
        .b(pre_clk_counter_register_dout), 
        .gt_eq(gt_eq)
    );

    assign compare_out = gt_eq;

    Register #(.DATA_WIDTH(32)) pre_clk_counter_register (
        .clk(clk), 
        .rst(pre_clk_register_rst), 
        .wr_en(pre_clk_register_wr_en), 
        .din(clk_counter_count), 
        .dout(pre_clk_counter_register_dout)
    );


    Memory #(
        .ADDR_WIDTH(10),
        .DATA_WIDTH(10),
        .INIT_FILE(Similar_neuron_INIT_FILE)
    ) similar_neuron_list_memory (
        .clk(clk),
        .rst(rst),
        .wr_en(1'b0), // No write operation in this module
        .addr(similar_neuron_counter_count), // Use the counter as address
        .din(10'b0), // No data input since we are not writing
        .dout(neuron_address)
    );


    reconfig_packet_generator #(
        .neuron_address_size(10)
    ) reconfig_packet_gen (
        .neuron_list_memory_dout(neuron_address),
        .change_value(change_value),
        .reconfig_packet(reconfig_packet)
    );


endmodule