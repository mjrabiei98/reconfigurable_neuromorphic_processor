module reconfig_pe_controller(
    input wire        clk,
    input wire        rst,
    input wire        similar_neuron_counter_reached,
    input wire        clk_counter_reached,
    input wire        interval_counter_reached,
    input wire        all_tile_done_communicating,
    input wire        send_done_wrapper,
    input wire        compare_out,

    output reg        similar_neuron_counter_en,
    output reg        similar_neuron_counter_rst,
    // output reg        similar_neuron_counter_load,
    output reg        clk_counter_en,
    output reg        clk_counter_rst,
    output reg        clk_counter_load,
    output reg        interval_counter_en,
    output reg        interval_counter_rst,
    // output reg        interval_counter_load,
    output reg        pre_clk_register_wr_en,
    output reg        pre_clk_register_rst,
    output reg        send,
    output reg        change_value
);


    reg[3:0] n_state, p_state;
  
    parameter idle_state = 3'b000, count_state = 3'b001, compare_state = 3'b010,
        send_reconfig_packet_state_1 = 3'b011,
        // wait_for_ack_state = 3'b100, 
        send_reconfig_packet_state_2 = 3'b101,
        done_reconfig_state = 3'b110;
            
    always@(posedge clk, rst)begin
        if(rst) p_state <= idle_state;
        else p_state <= n_state;
    end

    always@(*) 
    begin
        {

            similar_neuron_counter_en,
            similar_neuron_counter_rst,
            // similar_neuron_counter_load,
            clk_counter_en,
            clk_counter_rst,
            clk_counter_load,
            interval_counter_en,
            interval_counter_rst,
            // interval_counter_load,
            pre_clk_register_wr_en,
            pre_clk_register_rst,
            change_value,
            send

        } = 11'b0;


        case(p_state)
            idle_state: begin 
                n_state = similar_neuron_counter_reached ? idle_state : count_state;
                // similar_neuron_counter_load = 1'b1;
                similar_neuron_counter_rst = 1'b1;
                interval_counter_rst = 1'b1;
                // interval_counter_load = 1'b1;
                interval_counter_rst = 1'b1;
                clk_counter_rst = 1'b1;
                pre_clk_register_rst = 1'b1;
            end

            count_state: begin 
                n_state = interval_counter_reached ? compare_state : count_state;
                clk_counter_en = 1'b1;
                interval_counter_en = all_tile_done_communicating;
            end

            compare_state: begin 
                n_state = compare_out ? send_reconfig_packet_state_1 : send_reconfig_packet_state_2;
            end

            send_reconfig_packet_state_1: begin 
                // n_state = send_done_wrapper ? send_reconfig_packet_state_2 : wait_for_ack_state;
                n_state = send_done_wrapper ? send_reconfig_packet_state_2 : send_reconfig_packet_state_1;
                pre_clk_register_wr_en = 1'b1;
                similar_neuron_counter_en = send_done_wrapper;
                send = 1'b1;

            end

            // wait_for_ack_state: begin 
            //     n_state = send_done_wrapper ? send_reconfig_packet_state_2 : wait_for_ack_state;
            //     send = 1'b1;
            // end

            send_reconfig_packet_state_2: begin 
                n_state = similar_neuron_counter_reached ? done_reconfig_state : count_state;
                n_state = send_done_wrapper ? (similar_neuron_counter_reached ? done_reconfig_state : count_state) : send_reconfig_packet_state_2;
                change_value = 1'b1;
                send = 1'b1;
            end


            done_reconfig_state: begin
                n_state = done_reconfig_state;
            end

            default: begin
                n_state = idle_state;
            end
        endcase
    end


endmodule




module send_reconfig_packet_wrapper (
    input clk,
    input rst,
    input send,
    input ack,
    output reg req,
    output reg send_done_wrapper
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

        req = 1'b0;
        send_done_wrapper = 1'b0;
        
        case(p_state)
            idle_state: begin 
                n_state = send ? req_to_router_state : idle_state;

            end

            req_to_router_state: begin 
                n_state = send_state;
                req = 1'b1;
            end

            // wait_for_ack_state: begin
            //     n_state = ack ? send_state : wait_for_ack_state;
            //     req = 1'b1;
            // end

            send_state: begin 
                n_state = ack ? idle_state : send_state;
                req = 1'b1;
                send_done_wrapper = ack ? 1'b1 : 1'b0;
            end

            default: n_state = idle_state;

        endcase
    end



endmodule

