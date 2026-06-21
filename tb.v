`timescale 1ns/1ps

module tb_comm_intervals_handshake;
    localparam integer NUMBER_OF_NEURON      = 4;
    localparam integer INPUT_FIFO_DATA_WIDTH = 8;
    localparam integer INPUT_FIFO_DEPTH      = 16;
    localparam integer G2L_DW                = 4;
    localparam integer G2L_AW                = 8;
    localparam integer LOCAL_W_DW            = 10;
    localparam integer LOCAL_W_AW            = 4;
    localparam integer MEMBRANE_W            = 8;
    localparam integer THR                   = 8;
    localparam integer SPIKE_CNT_W           = 4;
    localparam integer OUT_LOCAL_DW          = 8;
    localparam integer LOCAL2GLOBAL_DW       = 8;
    localparam integer OUTPUT_FIFO_DW        = 8;
    localparam integer OUTPUT_FIFO_DEPTH     = 16;
    localparam integer SHIFT                 = 1;

    reg clk;
    reg rst;

    // Router -> PE
    reg  [INPUT_FIFO_DATA_WIDTH-1:0] input_spike;
    reg                              req_from_router;
    wire                             ack_from_pe;

    // PE -> Router
    wire [OUTPUT_FIFO_DW-1:0]        output_spike;
    wire                             req_to_router;
    reg                              ack_from_router;

    reg inject_interval;
    wire output_fifo_empty_signal;
    wire done_transmiting;
    wire communitation_signal;

    integer accepted_incoming_flits;
    integer accepted_outgoing_flits;
    reg prev_comm;

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
        .clk(clk),
        .rst(rst),
        .inject_interval(inject_interval),
        .input_spike(input_spike),
        .output_spike(output_spike),
        .output_fifo_empty_signal(output_fifo_empty_signal),
        .done_transmiting(done_transmiting),
        .communitation_signal(communitation_signal),
        .req_to_router(req_to_router),
        .ack_from_router(ack_from_router),
        .req_from_router(req_from_router),
        .ack_from_pe(ack_from_pe)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic wait_for_comm_rise;
        begin
            while (communitation_signal !== 1'b1)
                @(posedge clk);
            @(negedge clk);
        end
    endtask

    task automatic send_flit_from_router;
        input [INPUT_FIFO_DATA_WIDTH-1:0] flit;
        begin
            @(negedge clk);
            input_spike      <= flit;
            req_from_router  <= 1'b1;
            $display("[%0t] ROUTER SEND start  flit=0x%0h", $time, flit);

            // Hold req+data stable until PE acknowledges this flit.
            while (ack_from_pe !== 1'b1)
                @(posedge clk);

            accepted_incoming_flits = accepted_incoming_flits + 1;
            $display("[%0t] ROUTER SEND acked flit=0x%0h", $time, flit);

            @(negedge clk);
            req_from_router <= 1'b0;
            input_spike     <= {INPUT_FIFO_DATA_WIDTH{1'b0}};

            // Wait for ack to drop before the next flit.
            while (ack_from_pe !== 1'b0)
                @(posedge clk);
        end
    endtask

    task automatic pulse_inject_interval;
        begin
            @(negedge clk);
            inject_interval <= 1'b1;
            $display("[%0t] inject_interval asserted", $time);
            @(posedge clk);
            @(negedge clk);
            inject_interval <= 1'b0;
            $display("[%0t] inject_interval deasserted", $time);
        end
    endtask

    task automatic send_interval_0;
        begin
            $display("\n[%0t] ===== communication window 0 opened =====", $time);
            send_flit_from_router(8'h12);
            send_flit_from_router(8'h12);
            send_flit_from_router(8'h12);
            send_flit_from_router(8'h34);
            send_flit_from_router(8'h34);
            send_flit_from_router(8'h56);
            send_flit_from_router(8'h12);
            send_flit_from_router(8'h34);
            pulse_inject_interval();
        end
    endtask

    task automatic send_interval_1;
        begin
            $display("\n[%0t] ===== communication window 1 opened =====", $time);
            send_flit_from_router(8'h1);
            // send_flit_from_router(8'h2);
            // send_flit_from_router(8'h3);
            pulse_inject_interval();
        end
    endtask

    task automatic send_interval_2;
        begin
            $display("\n[%0t] ===== communication window 2 opened =====", $time);
            // send_flit_from_router(8'h1);
            // send_flit_from_router(8'h2);
            // send_flit_from_router(8'h3);
            pulse_inject_interval();
        end
    endtask


    // Router-side receiver for PE output.
    // Generate one-cycle ack pulses repeatedly while req_to_router remains high,
    // so back-to-back flits can be acknowledged in the same communication window.
    always @(posedge clk) begin
        if (rst) begin
            ack_from_router <= 1'b0;
            accepted_outgoing_flits <= 0;
        end else begin
            if (ack_from_router) begin
                ack_from_router <= 1'b0;
            end else if (req_to_router) begin
                ack_from_router <= 1'b1;
                accepted_outgoing_flits <= accepted_outgoing_flits + 1;
                $display("[%0t] ROUTER RECV acked outgoing flit=0x%0h", $time, output_spike);
            end
        end
    end

    // Trace communication window edges.
    always @(posedge clk) begin
        prev_comm <= communitation_signal;
        if (!rst) begin
            if (!prev_comm && communitation_signal)
                $display("[%0t] COMMUNICATION signal rose", $time);
            if (prev_comm && !communitation_signal)
                $display("[%0t] COMMUNICATION signal fell", $time);
        end
    end

    // Cycle-by-cycle debug.
    always @(posedge clk) begin
        if (!rst) begin
            $display("t=%0t st=%0d comm=%b done=%b inj=%b req_in=%b ack_in=%b req_out=%b ack_out=%b in_empty=%b out_empty=%b ncnt=%0d scnt=%0d mem={%0d,%0d,%0d,%0d} out=0x%0h",
                     $time,
                     dut.pe_ctrl.p_state,
                     communitation_signal,
                     done_transmiting,
                     inject_interval,
                     req_from_router,
                     ack_from_pe,
                     req_to_router,
                     ack_from_router,
                     dut.pe_dpth.input_fifo_empty,
                     dut.pe_dpth.output_fifo_empty,
                     dut.pe_dpth.neuron_counter,
                     dut.pe_dpth.spike_counter_out,
                     dut.pe_dpth.neuron_0_memberane_reg_out,
                     dut.pe_dpth.neuron_1_memberane_reg_out,
                     dut.pe_dpth.neuron_2_memberane_reg_out,
                     dut.pe_dpth.neuron_3_memberane_reg_out,
                     output_spike);
        end
    end

    initial begin
        rst                     = 1'b1;
        input_spike             = {INPUT_FIFO_DATA_WIDTH{1'b0}};
        req_from_router         = 1'b0;
        ack_from_router         = 1'b0;
        inject_interval         = 1'b0;
        accepted_incoming_flits = 0;
        accepted_outgoing_flits = 0;
        prev_comm               = 1'b0;

        repeat (4) @(posedge clk);
        rst = 1'b0;
        $display("[%0t] releasing reset", $time);

        // First interval: inject only when communication opens.
        wait_for_comm_rise();
        send_interval_0();

        // Wait until this communication window closes.
        while (communitation_signal === 1'b1)
            @(posedge clk);

        // Second interval: wait for next communication window.
        wait_for_comm_rise();
        send_interval_1();


        while (communitation_signal === 1'b1)
            @(posedge clk);

        // Second interval: wait for next communication window.
        wait_for_comm_rise();
        send_interval_2();

        // Let PE finish and keep acknowledging outgoing flits.
        repeat (120) @(posedge clk);

        $display("# Final membranes: n0=%0d n1=%0d n2=%0d n3=%0d",
                 dut.pe_dpth.neuron_0_memberane_reg_out,
                 dut.pe_dpth.neuron_1_memberane_reg_out,
                 dut.pe_dpth.neuron_2_memberane_reg_out,
                 dut.pe_dpth.neuron_3_memberane_reg_out);
        $display("# Accepted incoming flits  = %0d", accepted_incoming_flits);
        $display("# Accepted outgoing flits  = %0d", accepted_outgoing_flits);
        $finish;
    end
endmodule
