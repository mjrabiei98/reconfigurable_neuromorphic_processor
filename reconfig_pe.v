module reconfig_pe # (
    parameter WIDTH = 21,
    parameter reconfig_after_interval = 4
) (
    input wire        clk,
    input wire        rst,
    input wire        router_ack,
    input wire        all_tile_done_communicating,
    output wire       [20:0] reconfig_packet,
    output wire       req_to_router 
);

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
    wire       send;
    wire      change_value;
    wire     send_done_wrapper;


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
        .reconfig_packet(reconfig_packet),
        .change_value(change_value)
    );

    

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
        .send(send),
        .change_value(change_value)
    );



    send_reconfig_packet_wrapper send_wrapper (
        .clk(clk),
        .rst(rst),
        .send(send),
        .ack(router_ack),
        .req(req_to_router),
        .send_done_wrapper(send_done_wrapper)
    );


endmodule