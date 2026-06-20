module reconfig_pe_controller();


    reg[3:0] n_state, p_state;
  
    parameter idle_state = 2'b00, count_state = 2'b01, compare_state = 2'b10,
        send_reconfig_packet_state = 2'b11;
            
    always@(posedge clk, rst)begin
        if(rst) p_state <= idle_state;
        else p_state <= n_state;
    end

    always@(*) 
    begin
        {en_similar_neuron_counter, similar_neuron_counter_reset} = 2'b0;
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