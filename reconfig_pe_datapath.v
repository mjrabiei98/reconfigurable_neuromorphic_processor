module reconfig_pe_datapath # (
    parameter WIDTH = 8,
    parameter reconfig_after_interval = 4,
    parameter neuron_list_size = 4,
    parameter all_dest = 4'b1111,
    parameter neuron_address_size = 10,
    parameter Similar_neuron_INIT_FILE = ""
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

    wire [WIDTH-1:0] similar_neuron_counter_count;
    wire [WIDTH-1:0] clk_counter_count;
    wire [WIDTH-1:0] interval_counter_count;
    wire [WIDTH-1:0] pre_clk_counter_register_dout;
    wire gt_eq; // output of comparator, 1 if clk_counter_count >= interval_counter_count
    wire [WIDTH-1:0] neuron_address; // address of the neuron to be reconfigured



    counter #(.COUNT_WIDTH(WIDTH)) clk_counter (
        .clk(clk),
        .rst(clk_counter_rst), 
        .en(clk_counter_en), 
        .load(clk_counter_load), 
        .end_point_in(), 
        .reached(clk_counter_reached), 
        .count(clk_counter_count)
    );



    counter #(.COUNT_WIDTH(WIDTH)) interval_counter (
        .clk(clk), 
        .rst(interval_counter_rst), 
        .en(interval_counter_en), 
        .load(interval_counter_load), 
        .end_point_in(), 
        .reached(interval_counter_reached), 
        .count(interval_counter_count)
    );


    counter #(.COUNT_WIDTH(WIDTH)) similar_neuron_counter (
        .clk(clk), 
        .rst(similar_neuron_counter_rst), 
        .en(similar_neuron_counter_en), 
        .load(similar_neuron_counter_load), 
        .end_point_in(), // end point is not set
        .reached(similar_neuron_counter_reached), 
        .count(similar_neuron_counter_count)
    );


    comparer #(.DATA_WIDTH(WIDTH)) compare_clk_interval (
        .a(clk_counter_count), 
        .b(pre_clk_counter_register_dout), 
        .gt_eq(gt_eq)
    );



    register #(.DATA_WIDTH(WIDTH)) pre_clk_counter_register (
        .clk(clk), 
        .rst(pre_clk_register_rst), 
        .wr_en(pre_clk_register_wr_en), 
        .din(clk_counter_count), 
        .dout(pre_clk_counter_register_dout)
    );


    Memory #(
        .ADDR_WIDTH(),
        .DATA_WIDTH(WIDTH),
        .INIT_FILE(Similar_neuron_INIT_FILE)
    ) neuron_list_memory (
        .clk(clk),
        .rst(rst),
        .wr_en(1'b0), // No write operation in this module
        .addr(similar_neuron_counter_count[$clog2(neuron_list_size)-1:0]), // Use the counter as address
        .din({WIDTH{1'b0}}), // No data input since we are not writing
        .dout(neuron_address)
    );


    reconfig_packet_generator #(
        .WIDTH(WIDTH),
        .neuron_address(neuron_address_size),
        .all_dest(all_dest)
    ) reconfig_packet_gen (
        .neuron_list_memory_dout(neuron_address),
        .reconfig_packet(reconfig_packet)
    );


endmodule