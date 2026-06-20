module reconfig_pe # (
    parameter WIDTH = 8,
    parameter reconfig_after_interval = 4
) (
    input wire        clk,
    input wire        rst,
    input wire       all_tile_done_reconfig, // not used in current implementation, can be used in future for more complex reconfiguration conditions
    output wire       reconfig_signal, // not used in current implementation, can be used in future to signal other components about the need for reconfiguration
    output wire       [WIDTH-1:0] reconfig_packet
);

/*

module reconfig_pe_datapath # (
    parameter WIDTH = 8,
    parameter reconfig_after_interval = 4
) (
    input wire        clk,
    input wire        rst,
    input wire        similar_neuron_counter_en,
    input wire        similar_neuron_counter_rst,
    input wire        similar_neuron_counter_load,
    input wire        clk_counter_en,
    input wire        clk_counter_rst,
    input wire        clk_counter_load,
    input wire        interval_counter_en,
    input wire        interval_counter_rst,
    input wire        interval_counter_load,
    input wire        pre_clk_register_wr_en,
    input wire        pre_clk_register_rst,

    output wire       similar_neuron_counter_reached,
    output wire       clk_counter_reached,
    output wire       interval_counter_reached,
    output wire       [WIDTH-1:0] reconfig_packet

);

*/

    wire        similar_neuron_counter_en;
    wire        similar_neuron_counter_rst;
    wire        similar_neuron_counter_load;
    wire        clk_counter_en;
    wire        clk_counter_rst;
    wire        clk_counter_load;
    wire        interval_counter_en;
    wire        interval_counter_rst;
    wire        interval_counter_load;
    wire        pre_clk_register_wr_en;
    wire        pre_clk_register_rst;

    wire       similar_neuron_counter_reached;
    wire       clk_counter_reached;
    wire       interval_counter_reached;


    reconfig_pe_datapath #(.WIDTH(WIDTH), .reconfig_after_interval(reconfig_after_interval)) datapath (
        .clk(clk),
        .rst(rst),
        .similar_neuron_counter_en(similar_neuron_counter_en),
        .similar_neuron_counter_rst(similar_neuron_counter_rst),
        .similar_neuron_counter_load(similar_neuron_counter_load),
        .clk_counter_en(clk_counter_en),
        .clk_counter_rst(clk_counter_rst),
        .clk_counter_load(clk_counter_load),
        .interval_counter_en(interval_counter_en),
        .interval_counter_rst(interval_counter_rst),
        .interval_counter_load(interval_counter_load),
        .pre_clk_register_wr_en(pre_clk_register_wr_en),
        .pre_clk_register_rst(pre_clk_register_rst),
        .similar_neuron_counter_reached(similar_neuron_counter_reached),
        .clk_counter_reached(clk_counter_reached),
        .interval_counter_reached(interval_counter_reached),
        .reconfig_packet(reconfig_packet)
    );


    /*
    module reconfig_pe_controller(
    input wire        clk,
    input wire        rst,
    input wire       similar_neuron_counter_reached,
    input wire       clk_counter_reached,
    input wire       interval_counter_reached,
    input wire       all_tile_done_reconfig,

    output reg        similar_neuron_counter_en,
    output reg        similar_neuron_counter_rst,
    output reg        similar_neuron_counter_load,
    output reg        clk_counter_en,
    output reg        clk_counter_rst,
    output reg        clk_counter_load,
    output reg        interval_counter_en,
    output reg        interval_counter_rst,
    output reg        interval_counter_load,
    output reg        pre_clk_register_wr_en,
    output reg        pre_clk_register_rst,
    output reg        reconfig_signal
);

    
    */

    reconfig_pe_controller #(.WIDTH(WIDTH)) controller (
        .clk(clk),
        .rst(rst),
        .similar_neuron_counter_reached(similar_neuron_counter_reached),
        .clk_counter_reached(clk_counter_reached),
        .interval_counter_reached(interval_counter_reached),
        .all_tile_done_reconfig(all_tile_done_reconfig), // not connected

        .similar_neuron_counter_en(similar_neuron_counter_en),
        .similar_neuron_counter_rst(similar_neuron_counter_rst),
        .similar_neuron_counter_load(similar_neuron_counter_load),
        .clk_counter_en(clk_counter_en),
        .clk_counter_rst(clk_counter_rst),
        .clk_counter_load(clk_counter_load),
        .interval_counter_en(interval_counter_en),
        .interval_counter_rst(interval_counter_rst),
        .interval_counter_load(interval_counter_load),
        .pre_clk_register_wr_en(pre_clk_register_wr_en),
        .pre_clk_register_rst(pre_clk_register_rst),
        .reconfig_signal(reconfig_signal)
    );


endmodule