


module PE #(parameter 
    weight_mem_data_width = 32,
    weight_mem_0_init_file = "",
    weight_mem_1_init_file = "",
    weight_mem_2_init_file = "",
    weight_mem_3_init_file = "",
    changed_neuron_location_memory_init_file = "",
    mapped_neuron_memory_init_file = "",
    thr_reg_init_value = 8,


    spike_counter_width = 10,
    output_spike_local_mem_init_file = "",

    local_spike_to_global_address_mem_init_file = "",
    output_fifo_depth = 32,
    number_right_shift = 2,
    packet_width = 21

    )(
    input clk, rst, inject_interval,
    input [packet_width-1:0] input_spike,
    output [packet_width-1:0] output_spike,
    output output_fifo_empty_signal, done_transmiting, communitation_signal,
    output req_to_router,
    input ack_from_router,
    input req_from_router,
    output ack_from_pe
    );



/*
module PE_controller  (input clk, rst, input_fifo_full, input_fifo_empty, comparator_0_out, comparator_1_out, comparator_2_out, comparator_3_out,
                             neruron_counter_reached, spike_counter_reached, output_fifo_full, output_fifo_empty,
                             all_pe_done_communicating,
                       input [2:0] neuron_counter,
                       input [1:0]post_local_index,
                       output reg input_spike_fifo_wr_en, 
                              input_spike_fifo_rd_en, 
                              global_to_local_address_mem_wr_en, local_weight_mem_wr_en,
                              neuron_0_memberane_reg_wr_en, neuron_1_memberane_reg_wr_en, neuron_2_memberane_reg_wr_en, neuron_3_memberane_reg_wr_en,
                              neuron_counter_en, neuron_counter_load, spike_counter_en, spike_counter_load, output_spike_local_mem_wr_en,
                              local_spike_to_global_address_mem_wr_en, output_fifo_wr_en, output_fifo_rd_en);


*/
    // wire rd_output_fifo_noc, wr_input_fifo_noc;

    wire push_input, pop_output;
    
    wire input_fifo_full, input_fifo_empty, comparator_0_out, comparator_1_out, comparator_2_out, comparator_3_out,
         neruron_counter_reached, spike_counter_reached, output_fifo_full, output_fifo_empty;
    wire [2:0] neuron_counter;
    wire [1:0]post_local_index;
    wire input_spike_fifo_wr_en, 
         input_spike_fifo_rd_en, 
         global_to_local_address_mem_wr_en, local_weight_mem_wr_en,
         neuron_0_memberane_reg_wr_en, neuron_1_memberane_reg_wr_en, neuron_2_memberane_reg_wr_en, neuron_3_memberane_reg_wr_en,
         neuron_counter_en, neuron_counter_load, spike_counter_en, spike_counter_load, output_spike_local_mem_wr_en,
         local_spike_to_global_address_mem_wr_en, output_fifo_wr_en, output_fifo_rd_en;

    wire neuron_counter_rst, spike_counter_rst;
    wire [1:0] membrane_mux_sel; 
    wire adder_cin, wight_mux_sel;

    wire neuron_0_memberane_reg_wr_rst;
    wire neuron_1_memberane_reg_wr_rst;
    wire neuron_2_memberane_reg_wr_rst;
    wire neuron_3_memberane_reg_wr_rst;
    wire send, receive;
    wire reconfig_mux_sel;
    wire reconfig_signal;
    wire neural_location_status_wr_en;

    PE_controller pe_ctrl(.clk(clk), .rst(rst), .input_fifo_full(input_fifo_full), .input_fifo_empty(input_fifo_empty), .comparator_0_out(comparator_0_out), .comparator_1_out(comparator_1_out), 
                          .comparator_2_out(comparator_2_out), .comparator_3_out(comparator_3_out),
                          .neruron_counter_reached(neruron_counter_reached), .spike_counter_reached(spike_counter_reached), .output_fifo_full(output_fifo_full), .output_fifo_empty(output_fifo_empty),
                          .inject_interval(inject_interval),
                          .neuron_counter(neuron_counter),
                          .post_local_index(post_local_index),
                          .input_spike_fifo_wr_en(input_spike_fifo_wr_en), 
                          .input_spike_fifo_rd_en(input_spike_fifo_rd_en), 
                          .global_to_local_address_mem_wr_en(global_to_local_address_mem_wr_en), .local_weight_mem_wr_en(local_weight_mem_wr_en),
                          .neuron_0_memberane_reg_wr_en(neuron_0_memberane_reg_wr_en), .neuron_1_memberane_reg_wr_en(neuron_1_memberane_reg_wr_en), 
                          .neuron_2_memberane_reg_wr_en(neuron_2_memberane_reg_wr_en), .neuron_3_memberane_reg_wr_en(neuron_3_memberane_reg_wr_en),
                          .neuron_counter_en(neuron_counter_en), .neuron_counter_load(neuron_counter_load), .spike_counter_en(spike_counter_en), 
                          .spike_counter_load(spike_counter_load), .output_spike_local_mem_wr_en(output_spike_local_mem_wr_en),
                          .local_spike_to_global_address_mem_wr_en(local_spike_to_global_address_mem_wr_en), .output_fifo_wr_en(output_fifo_wr_en), .output_fifo_rd_en(output_fifo_rd_en),
                          .done_transmiting(done_transmiting), .communitation_signal(communitation_signal), .neuron_counter_rst(neuron_counter_rst), 
                          .spike_counter_rst(spike_counter_rst),
                          .membrane_mux_sel(membrane_mux_sel),
                          .adder_cin(adder_cin),
                          .wight_mux_sel(wight_mux_sel),
                          .neuron_0_memberane_reg_wr_rst(neuron_0_memberane_reg_wr_rst),
                          .neuron_1_memberane_reg_wr_rst(neuron_1_memberane_reg_wr_rst),
                          .neuron_2_memberane_reg_wr_rst(neuron_2_memberane_reg_wr_rst),
                          .neuron_3_memberane_reg_wr_rst(neuron_3_memberane_reg_wr_rst),
                          .send(send),
                          .receive(receive),
                          .reconfig_mux_sel(reconfig_mux_sel),
                          .reconfig_signal(reconfig_signal),
                          .neural_location_status_wr_en(neural_location_status_wr_en)
    );


/*

module PE_datapath #(
    parameter 
    number_of_neuron = 4,
    input_fifo_data_width = 8,
    input_fifo_depth = 32,
    global_to_local_address_mem_init_file = "",
    global_to_local_address_mem_data_width = 32,
    global_to_local_address_mem_address_width = 32,
    local_weight_mem_data_width = 32,
    local_weight_mem_address_width = 32,
    local_weight_mem_init_file = "",
    membrane_reg_data_width = 32,
    thr_reg_init_file = "",
    spike_counter_width = 10,
    output_spike_local_mem_init_file = "",
    output_spike_local_mem_data_width = 32,
    local_spike_to_global_address_mem_init_file = "",
    local_spike_to_global_address_mem_data_width = 32,
    output_fifo_data_width = 8,
    output_fifo_depth = 32

)(
    input clk, rst,
    input_spike_fifo_wr_en, 
    input_spike_fifo_rd_en, 
    global_to_local_address_mem_wr_en, local_weight_mem_wr_en,
    neuron_0_memberane_reg_wr_en, neuron_1_memberane_reg_wr_en, neuron_2_memberane_reg_wr_en, neuron_3_memberane_reg_wr_en,
    neuron_counter_en, neuron_counter_load, spike_counter_en, spike_counter_load, output_spike_local_mem_wr_en,
    local_spike_to_global_address_mem_wr_en, output_fifo_wr_en, output_fifo_rd_en,

    input [input_fifo_data_width-1:0] input_spike_fifo_din,

    output input_fifo_full, input_fifo_empty, comparator_0_out, comparator_1_out, comparator_2_out, comparator_3_out,
           neruron_counter_reached, spike_counter_reached, output_fifo_full, output_fifo_empty,
    output [2:0] neuron_counter_out,
    output [1:0]post_local_index,
    output [output_fifo_data_width-1:0] output_spike

);

*/



/*

   weight_mem_data_width = 32,
    weight_mem_0_init_file = "",
    weight_mem_1_init_file = "",
    weight_mem_2_init_file = "",
    weight_mem_3_init_file = "",
    changed_neuron_location_memory_init_file = "",
    mapped_neuron_memory_init_file = "",
    thr_reg_init_value = 8,


    spike_counter_width = 10,
    output_spike_local_mem_init_file = "",

    local_spike_to_global_address_mem_init_file = "",
    output_fifo_depth = 32,
    number_right_shift = 2,
    packet_width = 21


*/

    PE_datapath #( 
        .weight_mem_data_width(weight_mem_data_width),
        .weight_mem_0_init_file(weight_mem_0_init_file),
        .weight_mem_1_init_file(weight_mem_1_init_file),
        .weight_mem_2_init_file(weight_mem_2_init_file),
        .weight_mem_3_init_file(weight_mem_3_init_file),
        .changed_neuron_location_memory_init_file(changed_neuron_location_memory_init_file),
        .mapped_neuron_memory_init_file(mapped_neuron_memory_init_file),
        .thr_reg_init_value(thr_reg_init_value),
        .spike_counter_width(spike_counter_width),
        .output_spike_local_mem_init_file(output_spike_local_mem_init_file),
        .local_spike_to_global_address_mem_init_file(local_spike_to_global_address_mem_init_file),
        .output_fifo_depth(output_fifo_depth),
        .number_right_shift(number_right_shift),
        .packet_width(packet_width)
    ) 
    pe_dpth 
    (
        .clk(clk), .rst(rst),
        .input_spike_fifo_wr_en(push_input), 
        .input_spike_fifo_rd_en(input_spike_fifo_rd_en), 
        .global_to_local_address_mem_wr_en(global_to_local_address_mem_wr_en), .local_weight_mem_wr_en(local_weight_mem_wr_en),
        .neuron_0_memberane_reg_wr_en(neuron_0_memberane_reg_wr_en), .neuron_1_memberane_reg_wr_en(neuron_1_memberane_reg_wr_en), 
        .neuron_2_memberane_reg_wr_en(neuron_2_memberane_reg_wr_en), .neuron_3_memberane_reg_wr_en(neuron_3_memberane_reg_wr_en),
        .neuron_counter_en(neuron_counter_en), .neuron_counter_load(neuron_counter_load), .spike_counter_en(spike_counter_en), 
        .spike_counter_load(spike_counter_load), .output_spike_local_mem_wr_en(output_spike_local_mem_wr_en),
        .local_spike_to_global_address_mem_wr_en(local_spike_to_global_address_mem_wr_en), .output_fifo_wr_en(output_fifo_wr_en), .output_fifo_rd_en(pop_output),

        .input_spike_fifo_din(input_spike),

        .input_fifo_full(input_fifo_full), .input_fifo_empty(input_fifo_empty), .comparator_0_out(comparator_0_out), .comparator_1_out(comparator_1_out), 
        .comparator_2_out(comparator_2_out), .comparator_3_out(comparator_3_out),
        .neruron_counter_reached(neruron_counter_reached), .spike_counter_reached(spike_counter_reached), .output_fifo_full(output_fifo_full), .output_fifo_empty(output_fifo_empty),
        .neuron_counter_out(neuron_counter),
        .post_local_index(post_local_index),
        .output_spike(output_spike),
        .neuron_counter_rst(neuron_counter_rst), 
        .spike_counter_rst(spike_counter_rst),
        .membrane_mux_sel(membrane_mux_sel),
        .adder_cin(adder_cin),
        .wight_mux_sel(wight_mux_sel),
        .neuron_0_memberane_reg_wr_rst(neuron_0_memberane_reg_wr_rst),
        .neuron_1_memberane_reg_wr_rst(neuron_1_memberane_reg_wr_rst),
        .neuron_2_memberane_reg_wr_rst(neuron_2_memberane_reg_wr_rst),
        .neuron_3_memberane_reg_wr_rst(neuron_3_memberane_reg_wr_rst),
        .reconfig_mux_sel(reconfig_mux_sel),
        .reconfig_signal(reconfig_signal),
        .neural_location_status_wr_en(neural_location_status_wr_en)
    );



    

    receive_controller rc_ctrl(
        .clk(clk),
        .rst(rst),
        .receive(receive),
        .req(req_from_router),
        .ack(ack_from_pe),
        .push_flit(push_input)
    );

    send_controller    send_ctrl(
        .clk(clk),
        .rst(rst),
        .send(send),
        .req(req_to_router),
        .ack(ack_from_router),
        .pop_flit(pop_output)
    );


    
    assign output_fifo_empty_signal = output_fifo_empty;


endmodule