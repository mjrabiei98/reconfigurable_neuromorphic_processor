module PE_datapath #(
    parameter 
    number_of_neuron = 4,
    input_fifo_data_width = 8,
    input_fifo_depth = 32,
    global_to_local_address_mem_data_width = 32,
    global_to_local_address_mem_address_width = 32,
    weight_mem_address_width = 32,
    weight_mem_data_width = 32,
    weight_mem_0_init_file = "",
    weight_mem_1_init_file = "",
    weight_mem_2_init_file = "",
    weight_mem_3_init_file = "",
    local_weight_mem_data_width = 32,
    local_weight_mem_address_width = 32,
    membrane_reg_data_width = 32,
    thr_reg_init_value = 8,
    spike_counter_width = 10,
    output_spike_local_mem_init_file = "",
    output_spike_local_mem_data_width = 32,
    local_spike_to_global_address_mem_init_file = "",
    local_spike_to_global_address_mem_data_width = 32,
    output_fifo_data_width = 8,
    output_fifo_depth = 32,
    number_right_shift = 2,
    packet_width = 21

)(
    input clk, rst,
    input_spike_fifo_wr_en, 
    input_spike_fifo_rd_en, 
    global_to_local_address_mem_wr_en, local_weight_mem_wr_en,
    neuron_0_memberane_reg_wr_en, neuron_1_memberane_reg_wr_en, neuron_2_memberane_reg_wr_en, neuron_3_memberane_reg_wr_en,
    neuron_counter_en, neuron_counter_load, spike_counter_en, spike_counter_load, output_spike_local_mem_wr_en,
    local_spike_to_global_address_mem_wr_en, output_fifo_wr_en, output_fifo_rd_en, adder_cin, wight_mux_sel,
    neuron_counter_rst, spike_counter_rst,

    input [input_fifo_data_width-1:0] input_spike_fifo_din,

    input [1:0] membrane_mux_sel,
    input neuron_0_memberane_reg_wr_rst,neuron_1_memberane_reg_wr_rst,neuron_2_memberane_reg_wr_rst,neuron_3_memberane_reg_wr_rst,
    input reconfig_mux_sel,

    output input_fifo_full, input_fifo_empty, comparator_0_out, comparator_1_out, comparator_2_out, comparator_3_out,
           neruron_counter_reached, spike_counter_reached, output_fifo_full, output_fifo_empty,
    output [2:0] neuron_counter_out,
    output [1:0]post_local_index,
    output [output_fifo_data_width-1:0] output_spike

);

    wire [input_fifo_data_width-1:0] input_spike_fifo_dout;
    wire [global_to_local_address_mem_data_width-1:0] global_to_local_address_mem_output;
    wire [local_weight_mem_data_width-1:0] local_weight_mem_input, local_weight_mem_output;
    wire [weight_mem_data_width - 1 : 0 ] weight_mem_0_output;
    wire [weight_mem_data_width - 1 : 0 ] weight_mem_1_output;
    wire [weight_mem_data_width - 1 : 0 ] weight_mem_2_output;
    wire [weight_mem_data_width - 1 : 0 ] weight_mem_3_output;
    wire [membrane_reg_data_width-1:0] membrane_adder_out, neuron_0_memberane_reg_out, neuron_1_memberane_reg_out, 
        neuron_2_memberane_reg_out, neuron_3_memberane_reg_out, membrane_mux_out;
    wire [membrane_reg_data_width-1:0] thr_reg_0_out, thr_reg_1_out, thr_reg_2_out, thr_reg_3_out;
    wire [weight_mem_data_width-1:0] weight_mem_mux_out;
    wire [spike_counter_width-1:0] spike_counter_out;
    wire [2*spike_counter_width-1:0] output_spike_local_mem_out;
    wire [spike_counter_width-1:0] adder2_out;
    wire [9:0] local_spike_to_global_address_mem_out;
    wire [local_weight_mem_data_width-3:0] weight_shifter_out;
    wire [local_weight_mem_data_width-3:0] weight_inverter_out;
    wire [local_weight_mem_data_width-3:0] weight_mux_out;
    wire [packet_width-1:0] generated_spike_packet;

    wire [9:0] output_spike_mux_out;
    wire [9:0] reconfig_mux_out;
    wire neuron_location_status_out;
    wire [9:0]changed_neuron_location_memory_out;
    wire [9:0]mapped_neuron_memory_out;


    fifo #(
        .DATA_WIDTH(input_fifo_data_width), 
        .DEPTH(input_fifo_depth)
        ) input_spike_fifo(
            .clk(clk), 
            .rst(rst), 
            .wr_en(input_spike_fifo_wr_en), 
            .rd_en(input_spike_fifo_rd_en), 
            .din(input_spike_fifo_din), 
            .dout(input_spike_fifo_dout), 
            .full(input_fifo_full), 
            .empty(input_fifo_empty)
        );




    // Memory #(.ADDR_WIDTH(global_to_local_address_mem_address_width), .DATA_WIDTH(global_to_local_address_mem_data_width), .INIT_FILE(global_to_local_address_mem_init_file)) global_to_local_address_mem(.clk(clk), .rst(rst), .wr_en(global_to_local_address_mem_wr_en), .addr(input_spike_fifo_dout), .din(), .dout(global_to_local_address_mem_output));
    // Memory #(.ADDR_WIDTH(local_weight_mem_address_width), .DATA_WIDTH(local_weight_mem_data_width), .INIT_FILE(local_weight_mem_init_file)) local_weight_mem(.clk(clk), .rst(rst), .wr_en(local_weight_mem_wr_en), .addr(global_to_local_address_mem_output), .din(local_weight_mem_input), .dout(local_weight_mem_output));
    Memory #(
        .ADDR_WIDTH(weight_mem_address_width), 
        .DATA_WIDTH(weight_mem_data_width), 
        .INIT_FILE(weight_mem_0_init_file)) 
    weight_mem0(
        .clk(clk), 
        .rst(rst), 
        .wr_en(local_weight_mem_wr_en), 
        .addr(input_spike_fifo_dout[19:10]), 
        .din(), 
        .dout()
    );

    Memory #(
        .ADDR_WIDTH(weight_mem_address_width), 
        .DATA_WIDTH(weight_mem_data_width), 
        .INIT_FILE(weight_mem_1_init_file)) 
    weight_mem1(
        .clk(clk), 
        .rst(rst), 
        .wr_en(local_weight_mem_wr_en), 
        .addr(input_spike_fifo_dout[19:10]), 
        .din(), 
        .dout(weight_mem_1_output)
    );

    Memory #(
        .ADDR_WIDTH(weight_mem_address_width), 
        .DATA_WIDTH(weight_mem_data_width), 
        .INIT_FILE(weight_mem_2_init_file)) 
    weight_mem2(
        .clk(clk), 
        .rst(rst), 
        .wr_en(local_weight_mem_wr_en), 
        .addr(input_spike_fifo_dout[19:10]), 
        .din(), 
        .dout(weight_mem_2_output)
    );
    

    Memory #(
        .ADDR_WIDTH(weight_mem_address_width), 
        .DATA_WIDTH(weight_mem_data_width), 
        .INIT_FILE(weight_mem_3_init_file)) 
    weight_mem3(
        .clk(clk), 
        .rst(rst), 
        .wr_en(local_weight_mem_wr_en), 
        .addr(input_spike_fifo_dout[19:10]), 
        .din(), 
        .dout(weight_mem_3_output)
    );
    

    mux4to1 #(
        .DATA_WIDTH(weight_mem_data_width)
    ) weight_memory_mux( 
        .in0(weight_mem_0_output), 
        .in1(weight_mem_1_output), 
        .in2(weight_mem_2_output), 
        .in3(weight_mem_3_output), 
        .sel(input_spike_fifo_dout[1:0]), 
        .out(weight_mem_mux_out)
    );




    
    Adder #(
        .DATA_WIDTH(local_weight_mem_data_width-2)
    ) memberane_adder (
        .a(weight_mux_out), 
        .b(membrane_mux_out), 
        .sum(membrane_adder_out), 
        .cin(adder_cin)
    );
    
    shifter #(.number_right_shift(number_right_shift), .DATA_WIDTH(local_weight_mem_data_width-2)) weight_shifter(.din(membrane_mux_out), .dout(weight_shifter_out));
    not_each_bit #(.DATA_WIDTH(local_weight_mem_data_width-2)) weight_inverter(.in(weight_shifter_out), .out(weight_inverter_out));

    mux2to1 #(.DATA_WIDTH(weight_mem_data_width)) weight_mux(.in0(weight_mem_mux_out), .in1(weight_inverter_out), .sel(input_spike_fifo_dout[1:0]), .out(weight_mux_out)); // ???? selectesh chie????
    



    Register #(.DATA_WIDTH(membrane_reg_data_width)) neuron_0_memberane_reg (.clk(clk), .rst(rst || neuron_0_memberane_reg_wr_rst), .wr_en(neuron_0_memberane_reg_wr_en), .din(membrane_adder_out), .dout(neuron_0_memberane_reg_out));
    Register #(.DATA_WIDTH(membrane_reg_data_width)) neuron_1_memberane_reg (.clk(clk), .rst(rst || neuron_1_memberane_reg_wr_rst), .wr_en(neuron_1_memberane_reg_wr_en), .din(membrane_adder_out), .dout(neuron_1_memberane_reg_out));
    Register #(.DATA_WIDTH(membrane_reg_data_width)) neuron_2_memberane_reg (.clk(clk), .rst(rst || neuron_2_memberane_reg_wr_rst), .wr_en(neuron_2_memberane_reg_wr_en), .din(membrane_adder_out), .dout(neuron_2_memberane_reg_out));
    Register #(.DATA_WIDTH(membrane_reg_data_width)) neuron_3_memberane_reg (.clk(clk), .rst(rst || neuron_3_memberane_reg_wr_rst), .wr_en(neuron_3_memberane_reg_wr_en), .din(membrane_adder_out), .dout(neuron_3_memberane_reg_out));


    assign post_local_index = input_spike_fifo_dout[1:0];

    /*local_weight_mem_output  bara sel bayad bakhshish entekhab she*/
    mux4to1 #(.DATA_WIDTH(membrane_reg_data_width)) membrane_mux( .in0(neuron_0_memberane_reg_out), .in1(neuron_1_memberane_reg_out), .in2(neuron_2_memberane_reg_out), .in3(neuron_3_memberane_reg_out), .sel(membrane_mux_sel), .out(membrane_mux_out));



 

    /* bayad bekhunim az ru file be soorate init_file + neuron_number */
    Register_initable #(.DATA_WIDTH(membrane_reg_data_width), .THRESHOLD_VALUE(thr_reg_init_value)) neuron_0_thr_reg (.clk(clk), .rst(rst), .wr_en(), .din(), .dout(thr_reg_0_out));
    Register_initable #(.DATA_WIDTH(membrane_reg_data_width), .THRESHOLD_VALUE(thr_reg_init_value)) neuron_1_thr_reg (.clk(clk), .rst(rst), .wr_en(), .din(), .dout(thr_reg_1_out));
    Register_initable #(.DATA_WIDTH(membrane_reg_data_width), .THRESHOLD_VALUE(thr_reg_init_value)) neuron_2_thr_reg (.clk(clk), .rst(rst), .wr_en(), .din(), .dout(thr_reg_2_out));
    Register_initable #(.DATA_WIDTH(membrane_reg_data_width), .THRESHOLD_VALUE(thr_reg_init_value)) neuron_3_thr_reg (.clk(clk), .rst(rst), .wr_en(), .din(), .dout(thr_reg_3_out));



    comparator #(.DATA_WIDTH(membrane_reg_data_width)) comparator_0 (.a(neuron_0_memberane_reg_out), .b(thr_reg_0_out), .gt_eq(comparator_0_out));
    comparator #(.DATA_WIDTH(membrane_reg_data_width)) comparator_1 (.a(neuron_1_memberane_reg_out), .b(thr_reg_1_out), .gt_eq(comparator_1_out));
    comparator #(.DATA_WIDTH(membrane_reg_data_width)) comparator_2 (.a(neuron_2_memberane_reg_out), .b(thr_reg_2_out), .gt_eq(comparator_2_out));
    comparator #(.DATA_WIDTH(membrane_reg_data_width)) comparator_3 (.a(neuron_3_memberane_reg_out), .b(thr_reg_3_out), .gt_eq(comparator_3_out));




    counter #(.COUNT_WIDTH(3)) neuron_counter(.clk(clk), .rst(rst || neuron_counter_rst), .en(neuron_counter_en), .load(neuron_counter_load), .end_point_in(3'd4), .reached(neruron_counter_reached), .count(neuron_counter_out));
    counter #(.COUNT_WIDTH(spike_counter_width)) spike_counter(.clk(clk), .rst(rst || spike_counter_rst), .en(spike_counter_en), .load(spike_counter_load), .end_point_in(output_spike_local_mem_out[spike_counter_width-1:0]), .reached(spike_counter_reached), .count(spike_counter_out));





    Memory #(.ADDR_WIDTH(3), .DATA_WIDTH(2 * spike_counter_width), .INIT_FILE(output_spike_local_mem_init_file)) output_spike_local_mem (.clk(clk), .rst(rst), .wr_en(output_spike_local_mem_wr_en), .addr(neuron_counter_out), .din(), .dout(output_spike_local_mem_out));






    Adder #(.DATA_WIDTH(spike_counter_width)) adder2 (.a(output_spike_local_mem_out[2*spike_counter_width-1 : spike_counter_width]), .b(spike_counter_out), .sum(adder2_out), .cin(1'b0));




    Memory #(
        .ADDR_WIDTH(spike_counter_width), 
        .DATA_WIDTH(10), 
        .INIT_FILE(local_spike_to_global_address_mem_init_file)
    ) local_spike_to_global_address_mem (
        .clk(clk), 
        .rst(rst), 
        .wr_en(local_spike_to_global_address_mem_wr_en), 
        .addr(adder2_out), 
        .din(), 
        .dout(local_spike_to_global_address_mem_out)
    );



    Memory #(
        .ADDR_WIDTH(weight_mem_address_width), 
        .DATA_WIDTH(weight_mem_data_width), 
        .INIT_FILE(weight_mem_3_init_file)) 
    changed_neuron_location_memory(
        .clk(clk), 
        .rst(rst), 
        .wr_en(), 
        .addr(local_spike_to_global_address_mem_out), 
        .din(), 
        .dout(changed_neuron_location_memory_out)
    );


    Memory #(
        .ADDR_WIDTH(), 
        .DATA_WIDTH(), 
        .INIT_FILE()) 
    mapped_neuron_memory(
        .clk(clk), 
        .rst(rst), 
        .wr_en(), 
        .addr(neuron_counter_out), 
        .din(), 
        .dout(mapped_neuron_memory_out)
    );


    mux2to1 #(
        .DATA_WIDTH(10)
    ) reconfig_mux (
        .in0(local_spike_to_global_address_mem_out), 
        .in1(input_spike_fifo_dout[19:10]), 
        .sel(reconfig_mux_sel), 
        .out(reconfig_mux_out)
    );


    Memory #(
        .ADDR_WIDTH(), 
        .DATA_WIDTH(1), 
        .INIT_FILE("")) 
    neuron_location_status(
        .clk(clk), 
        .rst(rst), 
        .wr_en(), 
        .addr(reconfig_mux_out), 
        .din(input_spike_fifo_dout[0:0]), 
        .dout(neuron_location_status_out)
    );


    mux2to1 #(
        .DATA_WIDTH(10)
    ) output_spike_mux (
        .in0(local_spike_to_global_address_mem_out), 
        .in1(changed_neuron_location_memory_out), 
        .sel(neuron_location_status_out), 
        .out(output_spike_mux_out)
    );

    assign generated_spike_packet = {1'b0, mapped_neuron_memory_out ,output_spike_mux_out };


    fifo #(
        .DATA_WIDTH(packet_width), 
        .DEPTH(output_fifo_depth)) 
    output_spike_fifo(
        .clk(clk), 
        .rst(rst), 
        .wr_en(output_fifo_wr_en), 
        .rd_en(output_fifo_rd_en), 
        .din(generated_spike_packet), 
        .dout(output_spike), 
        .full(output_fifo_full), 
        .empty(output_fifo_empty)
    );



endmodule