// `timescale 1ns/1ps
// module tb_pe_smoke;
//     localparam integer NUMBER_OF_NEURON = 4;
//     localparam integer INPUT_FIFO_DATA_WIDTH = 8;
//     localparam integer INPUT_FIFO_DEPTH = 16;
//     localparam integer G2L_DW = 4;
//     localparam integer G2L_AW = 8;
//     localparam integer LOCAL_W_DW = 10;
//     localparam integer LOCAL_W_AW = 4;
//     localparam integer MEMBRANE_W = 8;
//     localparam integer THR = 4;
//     localparam integer SPIKE_CNT_W = 4;
//     localparam integer OUT_LOCAL_DW = 8;
//     localparam integer LOCAL2GLOBAL_DW = 8;
//     localparam integer OUTPUT_FIFO_DW = 8;
//     localparam integer OUTPUT_FIFO_DEPTH = 16;
//     localparam integer SHIFT = 1;

//     reg clk = 0;
//     reg rst = 1;
//     reg rd_output_fifo_noc = 0;
//     reg wr_input_fifo_noc = 0;
//     reg inject_interval = 0;
//     reg [INPUT_FIFO_DATA_WIDTH-1:0] input_spike = 0;

//     wire [OUTPUT_FIFO_DW-1:0] output_spike;
//     wire output_fifo_empty_signal;
//     wire done_transmiting;
//     wire communitation_signal;

//     PE #(
//         .number_of_neuron(NUMBER_OF_NEURON),
//         .input_fifo_data_width(INPUT_FIFO_DATA_WIDTH),
//         .input_fifo_depth(INPUT_FIFO_DEPTH),
//         .global_to_local_address_mem_init_file("g2l.mem"),
//         .global_to_local_address_mem_data_width(G2L_DW),
//         .global_to_local_address_mem_address_width(G2L_AW),
//         .local_weight_mem_data_width(LOCAL_W_DW),
//         .local_weight_mem_address_width(LOCAL_W_AW),
//         .local_weight_mem_init_file("local_weight.mem"),
//         .membrane_reg_data_width(MEMBRANE_W),
//         .thr_reg_init_value(THR),
//         .spike_counter_width(SPIKE_CNT_W),
//         .output_spike_local_mem_init_file("output_spike_local.mem"),
//         .output_spike_local_mem_data_width(OUT_LOCAL_DW),
//         .local_spike_to_global_address_mem_init_file("local_spike_to_global.mem"),
//         .local_spike_to_global_address_mem_data_width(LOCAL2GLOBAL_DW),
//         .output_fifo_data_width(OUTPUT_FIFO_DW),
//         .output_fifo_depth(OUTPUT_FIFO_DEPTH),
//         .number_right_shift(SHIFT)
//     ) dut (
//         .clk(clk), .rst(rst), .rd_output_fifo_noc(rd_output_fifo_noc), .wr_input_fifo_noc(wr_input_fifo_noc),
//         .inject_interval(inject_interval), .input_spike(input_spike), .output_spike(output_spike),
//         .output_fifo_empty_signal(output_fifo_empty_signal), .done_transmiting(done_transmiting), .communitation_signal(communitation_signal)
//     );

//     always #5 clk = ~clk;

//     task push_input(input [7:0] pkt);
//     begin
//         @(negedge clk);
//         input_spike = pkt;
//         wr_input_fifo_noc = 1'b1;
//         @(negedge clk);
//         wr_input_fifo_noc = 1'b0;
//         input_spike = 8'h00;
//     end
//     endtask

//     integer pop_count = 0;
//     always @(negedge clk) begin
//         rd_output_fifo_noc <= !output_fifo_empty_signal;
//         if (rd_output_fifo_noc && !output_fifo_empty_signal) begin
//             pop_count <= pop_count + 1;
//             $display("[%0t] POP output_spike = 0x%02h", $time, output_spike);
//         end
//     end

//     always @(posedge clk) begin
//         $display("t=%0t st=%0d in_empty=%b out_empty=%b ncnt=%0d scnt=%0d post=%0d mem={%0d,%0d,%0d,%0d} out=%02h",
//             $time, dut.pe_ctrl.p_state, dut.pe_dpth.input_fifo_empty, dut.pe_dpth.output_fifo_empty,
//             dut.pe_dpth.neuron_counter_out, dut.pe_dpth.spike_counter_out, dut.pe_dpth.post_local_index,
//             dut.pe_dpth.neuron_0_memberane_reg_out, dut.pe_dpth.neuron_1_memberane_reg_out,
//             dut.pe_dpth.neuron_2_memberane_reg_out, dut.pe_dpth.neuron_3_memberane_reg_out, output_spike);
//     end

//     initial begin
//         $dumpfile("tb_pe_smoke.vcd");
//         $dumpvars(0, tb_pe_smoke);
//         repeat (4) @(negedge clk);
//         rst = 0;
//         push_input(8'h12);
//         push_input(8'h34);
//         push_input(8'h56);
//         repeat (80) @(negedge clk);
//         $display("Final membranes: n0=%0d n1=%0d n2=%0d n3=%0d", dut.pe_dpth.neuron_0_memberane_reg_out, dut.pe_dpth.neuron_1_memberane_reg_out, dut.pe_dpth.neuron_2_memberane_reg_out, dut.pe_dpth.neuron_3_memberane_reg_out);
//         $display("Total output pops observed = %0d", pop_count);
//         $finish;
//     end
// endmodule

`timescale 1ns/1ps
module tb_pe_smoke;
    localparam integer NUMBER_OF_NEURON = 4;
    localparam integer INPUT_FIFO_DATA_WIDTH = 8;
    localparam integer INPUT_FIFO_DEPTH = 16;
    localparam integer G2L_DW = 4;
    localparam integer G2L_AW = 8;
    localparam integer LOCAL_W_DW = 10;
    localparam integer LOCAL_W_AW = 4;
    localparam integer MEMBRANE_W = 8;
    localparam integer THR = 20;
    localparam integer SPIKE_CNT_W = 4;
    localparam integer OUT_LOCAL_DW = 8;
    localparam integer LOCAL2GLOBAL_DW = 8;
    localparam integer OUTPUT_FIFO_DW = 8;
    localparam integer OUTPUT_FIFO_DEPTH = 16;
    localparam integer SHIFT = 1;

    reg clk = 0;
    reg rst = 1;
    reg rd_output_fifo_noc = 0;
    reg wr_input_fifo_noc = 0;
    reg inject_interval = 0;
    reg [INPUT_FIFO_DATA_WIDTH-1:0] input_spike = 0;

    wire [OUTPUT_FIFO_DW-1:0] output_spike;
    wire output_fifo_empty_signal;
    wire done_transmiting;
    wire communitation_signal;

    reg [MEMBRANE_W-1:0] prev_mem0, prev_mem1, prev_mem2, prev_mem3;

    PE #(
        .number_of_neuron(NUMBER_OF_NEURON),
        .input_fifo_data_width(INPUT_FIFO_DATA_WIDTH),
        .input_fifo_depth(INPUT_FIFO_DEPTH),
        .global_to_local_address_mem_init_file("g2l.mem"),
        .global_to_local_address_mem_data_width(G2L_DW),
        .global_to_local_address_mem_address_width(G2L_AW),
        .local_weight_mem_data_width(LOCAL_W_DW),
        .local_weight_mem_address_width(LOCAL_W_AW),
        .local_weight_mem_init_file("local_weight.mem"),
        .membrane_reg_data_width(MEMBRANE_W),
        .thr_reg_init_value(THR),
        .spike_counter_width(SPIKE_CNT_W),
        .output_spike_local_mem_init_file("output_spike_local.mem"),
        .output_spike_local_mem_data_width(OUT_LOCAL_DW),
        .local_spike_to_global_address_mem_init_file("local_spike_to_global.mem"),
        .local_spike_to_global_address_mem_data_width(LOCAL2GLOBAL_DW),
        .output_fifo_data_width(OUTPUT_FIFO_DW),
        .output_fifo_depth(OUTPUT_FIFO_DEPTH),
        .number_right_shift(SHIFT)
    ) dut (
        .clk(clk), .rst(rst), .rd_output_fifo_noc(rd_output_fifo_noc), .wr_input_fifo_noc(wr_input_fifo_noc),
        .inject_interval(inject_interval), .input_spike(input_spike), .output_spike(output_spike),
        .output_fifo_empty_signal(output_fifo_empty_signal), .done_transmiting(done_transmiting), .communitation_signal(communitation_signal)
    );

    always #5 clk = ~clk;

    task push_input(input [7:0] pkt);
    begin
        @(negedge clk);
        input_spike = pkt;
        wr_input_fifo_noc = 1'b1;
        $display("[%0t] INJECT input_spike = 0x%02h", $time, pkt);
        @(negedge clk);
        wr_input_fifo_noc = 1'b0;
        input_spike = 8'h00;
    end
    endtask

    task pulse_inject_interval;
    begin
        @(negedge clk);
        inject_interval = 1'b1;
        $display("[%0t] inject_interval asserted", $time);
        @(negedge clk);
        inject_interval = 1'b0;
        $display("[%0t] inject_interval deasserted", $time);
    end
    endtask

    task inject_burst_when_communication;
        input integer burst_id;
    begin
        wait (communitation_signal === 1'b1);
        @(negedge clk);
        $display("\n[%0t] ===== communication window %0d opened =====", $time, burst_id);

        case (burst_id)
            0: begin
                // Strong burst to force membrane build-up and output spike generation.
                push_input(8'h12);
                push_input(8'h12);
                push_input(8'h12);
                push_input(8'h34);
                push_input(8'h34);
                push_input(8'h56);
                push_input(8'h12);
                push_input(8'h34);
            end
            1: begin
                // Smaller burst after leakage interval so decay can be observed too.
                push_input(8'h12);
                push_input(8'h56);
                push_input(8'h56);
            end
            default: begin
                push_input(8'h12);
            end
        endcase

        $display("[%0t] burst %0d complete", $time, burst_id);
        pulse_inject_interval();
    end
    endtask

    integer pop_count = 0;
    always @(negedge clk) begin
        rd_output_fifo_noc <= !output_fifo_empty_signal;
        if (rd_output_fifo_noc && communitation_signal) begin
            pop_count <= pop_count + 1;
            $display("[%0t] POP output_spike = 0x%02h", $time, output_spike);
        end
    end

    // Detailed cycle-by-cycle view
    always @(posedge clk) begin
        $display("t=%0t st=%0d comm=%b inj_int=%b in_empty=%b out_empty=%b ncnt=%0d scnt=%0d post=%0d mem={%0d,%0d,%0d,%0d} cmp={%b,%b,%b,%b} out=%02h",
            $time, dut.pe_ctrl.p_state, communitation_signal, inject_interval,
            dut.pe_dpth.input_fifo_empty, dut.pe_dpth.output_fifo_empty,
            dut.pe_dpth.neuron_counter_out, dut.pe_dpth.spike_counter_out, dut.pe_dpth.post_local_index,
            dut.pe_dpth.neuron_0_memberane_reg_out, dut.pe_dpth.neuron_1_memberane_reg_out,
            dut.pe_dpth.neuron_2_memberane_reg_out, dut.pe_dpth.neuron_3_memberane_reg_out,
            dut.pe_dpth.comparator_0_out, dut.pe_dpth.comparator_1_out,
            dut.pe_dpth.comparator_2_out, dut.pe_dpth.comparator_3_out,
            output_spike);
    end

    // Highlight membrane changes so leakage is easy to observe in transcript.
    always @(posedge clk) begin
        if (!rst) begin
            if (dut.pe_dpth.neuron_0_memberane_reg_out != prev_mem0 ||
                dut.pe_dpth.neuron_1_memberane_reg_out != prev_mem1 ||
                dut.pe_dpth.neuron_2_memberane_reg_out != prev_mem2 ||
                dut.pe_dpth.neuron_3_memberane_reg_out != prev_mem3) begin
                $display("[%0t] MEM CHANGE st=%0d : n0 %0d->%0d | n1 %0d->%0d | n2 %0d->%0d | n3 %0d->%0d",
                    $time, dut.pe_ctrl.p_state,
                    prev_mem0, dut.pe_dpth.neuron_0_memberane_reg_out,
                    prev_mem1, dut.pe_dpth.neuron_1_memberane_reg_out,
                    prev_mem2, dut.pe_dpth.neuron_2_memberane_reg_out,
                    prev_mem3, dut.pe_dpth.neuron_3_memberane_reg_out);
            end

            if (dut.pe_ctrl.p_state == 3'd1) begin
                $display("[%0t] LEAKAGE phase: neuron_counter=%0d membrane_sel=%0d membrane_mux_out=%0d shifted=%0d adder_out=%0d",
                    $time,
                    dut.pe_dpth.neuron_counter_out,
                    dut.pe_ctrl.membrane_mux_sel,
                    dut.pe_dpth.membrane_mux_out,
                    dut.pe_dpth.weight_shifter_out,
                    dut.pe_dpth.membrane_adder_out);
            end
        end

        prev_mem0 <= dut.pe_dpth.neuron_0_memberane_reg_out;
        prev_mem1 <= dut.pe_dpth.neuron_1_memberane_reg_out;
        prev_mem2 <= dut.pe_dpth.neuron_2_memberane_reg_out;
        prev_mem3 <= dut.pe_dpth.neuron_3_memberane_reg_out;
    end

    initial begin
        $dumpfile("tb_pe_smoke.vcd");
        $dumpvars(0, tb_pe_smoke);

        prev_mem0 = 0;
        prev_mem1 = 0;
        prev_mem2 = 0;
        prev_mem3 = 0;

        repeat (4) @(negedge clk);
        rst = 0;

        // First communication window: inject enough spikes to trigger output generation.
        inject_burst_when_communication(0);

        // Let the PE process, generate outputs, and go through leakage/communication again.
        repeat (60) @(negedge clk);

        // Second communication window: smaller burst to observe another accumulation + leakage round.
        inject_burst_when_communication(1);

        // Allow enough time to observe output spikes leaving FIFO and subsequent leakage decay.
        repeat (160) @(negedge clk);

        $display("\nFinal membranes: n0=%0d n1=%0d n2=%0d n3=%0d",
            dut.pe_dpth.neuron_0_memberane_reg_out,
            dut.pe_dpth.neuron_1_memberane_reg_out,
            dut.pe_dpth.neuron_2_memberane_reg_out,
            dut.pe_dpth.neuron_3_memberane_reg_out);
        $display("Total output pops observed = %0d", pop_count);
        $finish;
    end
endmodule
