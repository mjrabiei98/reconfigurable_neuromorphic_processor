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


    reg[3:0] n_state, p_state;
  
    parameter idle_state = 2'b00, count_state = 2'b01, compare_state = 2'b10,
        send_reconfig_packet_state = 2'b11;
            
    always@(posedge clk, rst)begin
        if(rst) p_state <= idle_state;
        else p_state <= n_state;
    end

    always@(*) 
    begin
        {

            similar_neuron_counter_en,
            similar_neuron_counter_rst,
            similar_neuron_counter_load,
            clk_counter_en,
            clk_counter_rst,
            clk_counter_load,
            interval_counter_en,
            interval_counter_rst,
            interval_counter_load,
            pre_clk_register_wr_en,
            pre_clk_register_rst,
            reconfig_signal

        } = 12'b0;


        case(p_state)
            idle_state: begin 
                n_state = count_state;
                en_similar_neuron_counter = 1'b1;
            end
            count_state: begin 
                n_state = compare_state;
                en_similar_neuron_counter = 1'b1;
                similar_neuron_counter_reset = 1'b0;
            end
            compare_state: begin 
                n_state = (similar_neuron_counter_reached) ? send_reconfig_packet_state : count_state;
                en_similar_neuron_counter = 1'b0;
                similar_neuron_counter_reset = 1'b0;
            end
            send_reconfig_packet_state: begin 
                n_state = idle_state;
                en_similar_neuron_counter = 1'b0;
                similar_neuron_counter_reset = 1'b1;

            end
        endcase
    end


endmodule