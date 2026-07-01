`timescale 1ns/1ps

module tb_reconfig_pe_final;

    // ============================================================
    // Test parameters
    // ============================================================
    localparam integer WIDTH                       = 21;
    localparam integer RECONFIG_AFTER_INTERVAL     = 10;
    localparam integer CLK_PERIOD                  = 10;
    localparam integer NUM_RECONFIG_EVENTS_TO_TEST = 3;

    localparam integer EXPECTED_REQUESTS = NUM_RECONFIG_EVENTS_TO_TEST * 2;
    localparam integer EXPECTED_INTERVALS = NUM_RECONFIG_EVENTS_TO_TEST * RECONFIG_AFTER_INTERVAL;

    // Controller state encoding from reconfig_pe_controller.v
    // p_state is declared as 4 bits in your controller, but the encoded values are 3-bit values.
    localparam [3:0] IDLE_STATE                  = 4'b0000;
    localparam [3:0] COUNT_STATE                 = 4'b0001;
    localparam [3:0] COMPARE_STATE               = 4'b0010;
    localparam [3:0] SEND_PACKET_STATE_1         = 4'b0011;
    localparam [3:0] SEND_PACKET_STATE_2         = 4'b0101;
    localparam [3:0] DONE_RECONFIG_STATE         = 4'b0110;

    // ============================================================
    // DUT signals
    // ============================================================
    reg         clk;
    reg         rst;
    reg         router_ack;
    reg         all_tile_done_communicating;

    wire [20:0] reconfig_packet;
    wire        req_to_router;

    // ============================================================
    // DUT instantiation
    // ============================================================
    reconfig_pe #(
        .WIDTH(WIDTH),
        .reconfig_after_interval(RECONFIG_AFTER_INTERVAL)
    ) dut (
        .clk(clk),
        .rst(rst),
        .router_ack(router_ack),
        .all_tile_done_communicating(all_tile_done_communicating),
        .reconfig_packet(reconfig_packet),
        .req_to_router(req_to_router)
    );

    // ============================================================
    // Clock generation
    // ============================================================
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ============================================================
    // Router ACK model
    // ACK is returned one clock after req_to_router becomes high.
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            router_ack <= 1'b0;
        end else begin
            router_ack <= req_to_router;
        end
    end

    // ============================================================
    // Interval pulse task
    // This task waits until the DUT is really in COUNT_STATE before
    // applying one all_tile_done_communicating pulse.
    // ============================================================
    task send_one_interval;
    begin
        wait (dut.controller.p_state == COUNT_STATE);
        @(negedge clk);
        all_tile_done_communicating = 1'b1;
        @(negedge clk);
        all_tile_done_communicating = 1'b0;
        @(posedge clk);
    end
    endtask

    // ============================================================
    // Counters and checker variables
    // ============================================================
    integer accepted_interval_count;
    integer request_count;
    integer error_count;
    integer expected_event_number;
    integer expected_packet_in_event;
    integer expected_interval_count;
    integer wait_cycles;

    reg previous_req;

    // Count accepted intervals from the testbench point of view.
    // These are pulses presented while the controller is in COUNT_STATE.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            accepted_interval_count <= 0;
        end else begin
            if (all_tile_done_communicating && dut.controller.p_state == COUNT_STATE) begin
                accepted_interval_count <= accepted_interval_count + 1;
            end
        end
    end

    // ============================================================
    // Request and packet checker
    // Expected behavior:
    //   interval 10: packet 1 with change_value=0, packet 2 with change_value=1
    //   interval 20: packet 1 with change_value=0, packet 2 with change_value=1
    //   interval 30: packet 1 with change_value=0, packet 2 with change_value=1
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            previous_req  <= 1'b0;
            request_count <= 0;
            error_count   <= 0;
        end else begin
            previous_req <= req_to_router;

            if (req_to_router && !previous_req) begin
                request_count = request_count + 1;

                expected_event_number    = ((request_count - 1) / 2) + 1;
                expected_packet_in_event = ((request_count - 1) % 2) + 1;
                expected_interval_count  = expected_event_number * RECONFIG_AFTER_INTERVAL;

                $display("[%0t] REQ %0d | event=%0d packet=%0d | accepted_intervals=%0d | change_value=%0b | packet=%021b",
                         $time,
                         request_count,
                         expected_event_number,
                         expected_packet_in_event,
                         accepted_interval_count,
                         dut.controller.change_value,
                         reconfig_packet);

                // Timing check
                if (accepted_interval_count !== expected_interval_count) begin
                    $display("ERROR at %0t: request generated at wrong interval count. Expected %0d, got %0d.",
                             $time, expected_interval_count, accepted_interval_count);
                    error_count = error_count + 1;
                end

                // change_value check
                if (expected_packet_in_event == 1) begin
                    if (dut.controller.change_value !== 1'b0) begin
                        $display("ERROR at %0t: packet 1 should have change_value=0, got %0b.",
                                 $time, dut.controller.change_value);
                        error_count = error_count + 1;
                    end
                end else begin
                    if (dut.controller.change_value !== 1'b1) begin
                        $display("ERROR at %0t: packet 2 should have change_value=1, got %0b.",
                                 $time, dut.controller.change_value);
                        error_count = error_count + 1;
                    end
                end

                // Packet LSB check. Based on your current packet format, packet 1 ends in 0
                // and packet 2 ends in 1.
                if (reconfig_packet[0] !== dut.controller.change_value) begin
                    $display("ERROR at %0t: packet LSB does not match change_value. packet[0]=%0b, change_value=%0b.",
                             $time, reconfig_packet[0], dut.controller.change_value);
                    error_count = error_count + 1;
                end
            end
        end
    end

    // ============================================================
    // Main stimulus
    // Fixed problem:
    // The old testbench sent exactly 30 pulse attempts, but only 28 were
    // accepted because the DUT spends cycles in packet-sending states.
    // This version continues until 30 intervals are truly accepted.
    // ============================================================
    initial begin
        $dumpfile("reconfig_test_bench_fixed.vcd");
        $dumpvars(0, tb_reconfig_pe_final);

        rst = 1'b1;
        router_ack = 1'b0;
        all_tile_done_communicating = 1'b0;

        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (2) @(posedge clk);

        $display("============================================================");
        $display("Starting reconfig_pe test");
        $display("Expected: two packets after every %0d accepted intervals", RECONFIG_AFTER_INTERVAL);
        $display("Testing %0d reconfiguration events", NUM_RECONFIG_EVENTS_TO_TEST);
        $display("DUT top reconfig_after_interval      = %0d", dut.reconfig_after_interval);
        $display("DUT datapath reconfig_after_interval = %0d", dut.datapath.reconfig_after_interval);
        $display("============================================================");

        // Send intervals until the testbench has observed the required number
        // of accepted interval pulses, not just attempted pulses.
        while (accepted_interval_count < EXPECTED_INTERVALS) begin
            send_one_interval();
        end

        // Wait until all expected packet requests are observed.
        // A timeout prevents infinite simulation if the DUT gets stuck.
        wait_cycles = 0;
        while ((request_count < EXPECTED_REQUESTS) && (wait_cycles < 500)) begin
            @(posedge clk);
            wait_cycles = wait_cycles + 1;
        end

        repeat (10) @(posedge clk);

        $display("============================================================");
        $display("Finished reconfig_pe test");
        $display("Accepted intervals = %0d", accepted_interval_count);
        $display("Requests observed  = %0d", request_count);
        $display("Errors observed    = %0d", error_count);
        $display("============================================================");

        if (request_count !== EXPECTED_REQUESTS) begin
            $display("ERROR: expected %0d requests, but observed %0d requests.",
                     EXPECTED_REQUESTS, request_count);
            error_count = error_count + 1;
        end

        if (accepted_interval_count !== EXPECTED_INTERVALS) begin
            $display("ERROR: expected %0d accepted intervals, but observed %0d.",
                     EXPECTED_INTERVALS, accepted_interval_count);
            error_count = error_count + 1;
        end

        if (wait_cycles >= 500) begin
            $display("ERROR: timeout while waiting for expected packet requests.");
            error_count = error_count + 1;
        end

        if (error_count == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED with %0d error(s)", error_count);
        end

        $finish;
    end

endmodule
