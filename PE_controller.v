module PE_controller  (input clk, rst, input_fifo_full, input_fifo_empty, comparator_0_out, comparator_1_out, comparator_2_out, comparator_3_out,
                             neruron_counter_reached, spike_counter_reached, output_fifo_full, output_fifo_empty,
                             inject_interval, 
                             output reg adder_cin, wight_mux_sel,
                       input [2:0] neuron_counter,
                       input [1:0]post_local_index,
                       input reconfig_signal,
                       output reg input_spike_fifo_wr_en, 
                              input_spike_fifo_rd_en, 
                              global_to_local_address_mem_wr_en, local_weight_mem_wr_en,
                              neuron_0_memberane_reg_wr_en, neuron_1_memberane_reg_wr_en, neuron_2_memberane_reg_wr_en, neuron_3_memberane_reg_wr_en,
                              neuron_counter_en, neuron_counter_load, spike_counter_en, spike_counter_load, output_spike_local_mem_wr_en,
                              local_spike_to_global_address_mem_wr_en, output_fifo_wr_en, output_fifo_rd_en, done_transmiting, communitation_signal,
                              output reg [1:0] membrane_mux_sel, 
                              output reg neuron_counter_rst, spike_counter_rst,
                              output reg neuron_0_memberane_reg_wr_rst,neuron_1_memberane_reg_wr_rst,neuron_2_memberane_reg_wr_rst,neuron_3_memberane_reg_wr_rst,
                              output reg send,
                              output reg receive,
                              output reg reconfig_mux_sel,
                              output reg neural_location_status_wr_en
                              );

    reg[3:0] n_state, p_state;
  
    parameter initial_state = 4'b0000, read_fifo = 4'b0001, reconfigure_state = 4'b0010,
        read_local_weight = 4'b0011, update_membrane = 4'b0100, compare_with_threshold = 4'b0101,
        generate_output_spike = 4'b0110, check_neuron_location = 4'b0111, fill_output_fifo = 4'b1000, 
        send_and_receive = 4'b1001, done_neuron = 4'b1010, leakage = 4'b1011;
            
    always@(posedge clk, rst)begin
        if(rst) p_state <= initial_state;
        else p_state <= n_state;
    end

    always@(*) 
    begin
        {input_spike_fifo_wr_en, 
         input_spike_fifo_rd_en, 
         global_to_local_address_mem_wr_en, local_weight_mem_wr_en,
         neuron_0_memberane_reg_wr_en, neuron_1_memberane_reg_wr_en, neuron_2_memberane_reg_wr_en, neuron_3_memberane_reg_wr_en,
         neuron_counter_en, neuron_counter_load, spike_counter_en, spike_counter_load, output_spike_local_mem_wr_en,
         local_spike_to_global_address_mem_wr_en, output_fifo_wr_en, output_fifo_rd_en, done_transmiting, communitation_signal,wight_mux_sel,adder_cin,
         neuron_counter_rst, spike_counter_rst,neuron_0_memberane_reg_wr_rst,neuron_1_memberane_reg_wr_rst,
         neuron_2_memberane_reg_wr_rst,neuron_3_memberane_reg_wr_rst, send, receive, reconfig_mux_sel, neural_location_status_wr_en} = 30'b0;
         membrane_mux_sel =  post_local_index;
        
    case(p_state)
        initial_state: begin 
            n_state = leakage;
            neuron_counter_load = 1'b1;
        end
        leakage: begin 
            n_state = neruron_counter_reached ? ((input_fifo_empty == 1'b1) ? send_and_receive : read_fifo) : leakage;
            neuron_counter_en = 1'b1;
            wight_mux_sel = 1'b1; // select the inverted and shifted weight for leakage
            adder_cin = 1'b1; // add 1 for leakage
            neuron_0_memberane_reg_wr_en = (neuron_counter == 3'b000)? 1'b1 : 1'b0;
            neuron_1_memberane_reg_wr_en = (neuron_counter == 3'b001)? 1'b1 : 1'b0;
            neuron_2_memberane_reg_wr_en = (neuron_counter == 3'b010)? 1'b1 : 1'b0;
            neuron_3_memberane_reg_wr_en = (neuron_counter == 3'b011)? 1'b1 : 1'b0;
            membrane_mux_sel = neuron_counter[1:0]; // select which neuron's membrane potential to update for leakage

        end
        read_fifo : begin 
            n_state = reconfig_signal ? reconfigure_state : read_local_weight;
            input_spike_fifo_rd_en = 1'b1;
            neuron_counter_rst = 1'b1;
        end
        reconfigure_state: begin 
            n_state = read_fifo;
            reconfig_mux_sel = 1'b1;
            neural_location_status_wr_en = 1'b1;
        end
        read_local_weight: begin 
            n_state = update_membrane;
            
        end 
        update_membrane: begin 
            n_state = (input_fifo_empty == 1) ? compare_with_threshold : read_fifo;
            neuron_0_memberane_reg_wr_en = (post_local_index == 2'b00)? 1'b1 : 1'b0;
            neuron_1_memberane_reg_wr_en = (post_local_index == 2'b01)? 1'b1 : 1'b0;
            neuron_2_memberane_reg_wr_en = (post_local_index == 2'b10)? 1'b1 : 1'b0;
            neuron_3_memberane_reg_wr_en = (post_local_index == 2'b11)? 1'b1 : 1'b0;
            neuron_counter_load = 1'b1;

            


        end 
        compare_with_threshold : begin 
            n_state = (neuron_counter == 3'b000 & comparator_0_out == 1)? generate_output_spike : 
                      (neuron_counter == 3'b001 & comparator_1_out == 1)? generate_output_spike :
                      (neuron_counter == 3'b010 & comparator_2_out == 1)? generate_output_spike :
                      (neuron_counter == 3'b011 & comparator_3_out == 1)? generate_output_spike : done_neuron;

            spike_counter_load = 1'b1;
            // neuron_counter_en = 1'b1;

            neuron_0_memberane_reg_wr_rst = (neuron_counter == 3'b000 & comparator_0_out == 1);
            neuron_1_memberane_reg_wr_rst = (neuron_counter == 3'b001 & comparator_1_out == 1);
            neuron_2_memberane_reg_wr_rst = (neuron_counter == 3'b010 & comparator_2_out == 1);
            neuron_3_memberane_reg_wr_rst = (neuron_counter == 3'b011 & comparator_3_out == 1);

            
            
        end
        generate_output_spike:begin 
            n_state = check_neuron_location;
            spike_counter_en = 1'b1;

        end

        check_neuron_location: begin 
            n_state = fill_output_fifo;


        end 
        fill_output_fifo : begin 
            n_state = (spike_counter_reached == 0)? generate_output_spike : done_neuron;
            // spike_counter_en = 1'b1;
            output_fifo_wr_en = 1'b1;
            // neuron_counter_en = spike_counter_reached;
        end
        // done_neuron: begin 
        //     n_state = (!neruron_counter_reached) ? compare_with_threshold : send_and_receive;
        //     neuron_counter_en = 1'b1;
        // end


        done_neuron: begin
            if (neuron_counter == 3) begin
                n_state = send_and_receive;
                neuron_counter_en = 1'b0;
            end else begin
                n_state = compare_with_threshold;
                neuron_counter_en = 1'b1;
            end
        end
 
        send_and_receive : begin 
            n_state = (inject_interval & output_fifo_empty) ? leakage : send_and_receive;
            communitation_signal = 1'b1;
            spike_counter_rst = 1'b1;
            neuron_counter_rst = 1'b1;
            // output_fifo_rd_en = 1'b1;
            // output_fifo_rd_en = !output_fifo_empty;
            // input_spike_fifo_wr_en = 1'b1;
            send = !output_fifo_empty;
            receive = 1'b1;
        end

        default: n_state = initial_state;
    endcase


    end
endmodule


module receive_controller (
    input clk,
    input rst,
    input receive,
    input req,
    output reg ack,
    output reg push_flit
);
    reg [1:0] p_state,n_state;
    parameter idle_state = 2'b00;
    parameter wait_for_input_state = 2'b01;
    parameter receive_state = 2'b10; 

    always@(posedge clk, rst)begin
        if(rst) p_state <= idle_state;
        else p_state <= n_state;
    end

    always@(*) 
    begin
        {push_flit, ack} = 2'b0;
        
        case(p_state)
            idle_state: begin 
                n_state = receive ? wait_for_input_state : idle_state;
            end

            wait_for_input_state: begin 
                n_state = req ? receive_state : wait_for_input_state;
                push_flit = req;
            end

            receive_state: begin 
                n_state = receive ? wait_for_input_state : idle_state;
                ack = 1'b1;
            end

            default: n_state = idle_state;

        endcase
    end



endmodule


module send_controller (
    input clk,
    input rst,
    input send,
    input ack,
    output reg req,
    output reg pop_flit
);
    reg [1:0] p_state,n_state;
    parameter idle_state = 2'b00;
    parameter req_to_router_state = 2'b01;
    // parameter wait_for_ack_state = 2'b10;
    parameter send_state = 2'b10; 

    always@(posedge clk, rst)begin
        if(rst) p_state <= idle_state;
        else p_state <= n_state;
    end

    always@(*) 
    begin
        {req, pop_flit} = 2'b00;
        
        case(p_state)
            idle_state: begin 
                n_state = send ? req_to_router_state : idle_state;

            end

            req_to_router_state: begin 
                n_state = send_state;
                req = 1'b1;
                pop_flit = 1'b1;
            end

            // wait_for_ack_state: begin
            //     n_state = ack ? send_state : wait_for_ack_state;
            //     req = 1'b1;
            // end

            send_state: begin 
                n_state = (send & ack) ? req_to_router_state : (ack ? idle_state : send_state);
                req = 1'b1;
            end

            default: n_state = idle_state;

        endcase
    end



endmodule

