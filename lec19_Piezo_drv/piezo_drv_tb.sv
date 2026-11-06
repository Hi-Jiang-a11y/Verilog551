`timescale 1ns/1ps

module piezo_drv_tb #(
    parameter bit TB_FAST_SIM = 1'b1
);

    logic clk;
    logic rst_n;
    logic en_steer;
    logic too_fast;
    logic batt_low;
    logic piezo;
    logic piezo_n;

    logic tone_silent;
    logic tone_G6;
    logic tone_C7;
    logic tone_E7;
    logic tone_G7;

    integer error_count;

    localparam logic [2:0] S_WAIT     = 3'd0;
    localparam logic [2:0] S_G6       = 3'd1;
    localparam logic [2:0] S_C7       = 3'd2;
    localparam logic [2:0] S_E7       = 3'd3;
    localparam logic [2:0] S_G7       = 3'd4;
    localparam logic [2:0] S_E7_SHORT = 3'd5;
    localparam logic [2:0] S_G7_LONG  = 3'd6;

    localparam integer P_G6 = TB_FAST_SIM ? 498 : 31_888;
    localparam integer P_C7 = TB_FAST_SIM ? 373 : 23_889;
    localparam integer P_E7 = TB_FAST_SIM ? 296 : 18_961;
    localparam integer P_G7 = TB_FAST_SIM ? 249 : 15_944;

    localparam integer D_23 = TB_FAST_SIM ? 131_072 : 8_388_608;
    localparam integer D_22 = TB_FAST_SIM ? 65_536 : 4_194_304;
    localparam integer D_23_PLUS_22 = TB_FAST_SIM ? 196_608 : 12_582_912;
    localparam integer D_24 = TB_FAST_SIM ? 262_144 : 16_777_216;

    localparam integer REPEAT_LIMIT = TB_FAST_SIM ? 2_500_000 : 151_000_000;

    piezo_drv #(
        .FAST_SIM(TB_FAST_SIM)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .en_steer (en_steer),
        .too_fast (too_fast),
        .batt_low (batt_low),
        .piezo    (piezo),
        .piezo_n  (piezo_n)
    );

    always #5 clk = ~clk;

    // These signals are easier to read in GTKWave than a numeric frequency.
    always_comb begin
        tone_silent = 1'b0;
        tone_G6 = 1'b0;
        tone_C7 = 1'b0;
        tone_E7 = 1'b0;
        tone_G7 = 1'b0;

        case (dut.cs)
            S_G6:       tone_G6 = 1'b1;
            S_C7:       tone_C7 = 1'b1;
            S_E7:       tone_E7 = 1'b1;
            S_G7:       tone_G7 = 1'b1;
            S_E7_SHORT: tone_E7 = 1'b1;
            S_G7_LONG:  tone_G7 = 1'b1;
            default:    tone_silent = 1'b1;
        endcase
    end

`ifdef DUMP_VCD
    initial begin
        $dumpfile("piezo_drv.vcd");
        $dumpvars(0, piezo_drv_tb);
    end
`endif

    // Check whether the DUT reaches the expected state.
    task automatic check_state(
        input logic [2:0] expected,
        input integer limit
    );
        integer count;
        begin
            count = 0;

            while ((dut.cs !== expected) && (count < limit)) begin
                @(posedge clk);
                count = count + 1;
            end

            if (dut.cs !== expected) begin
                error_count = error_count + 1;
                $display(
                    "[ERROR] Timeout waiting for state %0d; current state=%0d",
                    expected, dut.cs
                );
            end
        end
    endtask

    // Check state, tone period and note duration.
    task automatic check_note(
        input logic [2:0] expected_state,
        input integer expected_period,
        input integer expected_duration,
        input integer limit
    );
        begin
            check_state(expected_state, limit);

            if (dut.tone_period !== expected_period[15:0]) begin
                error_count = error_count + 1;
                $display(
                    "[ERROR] State %0d period=%0d expected=%0d",
                    expected_state, dut.tone_period, expected_period
                );
            end

            if (dut.note_duration !== expected_duration[24:0]) begin
                error_count = error_count + 1;
                $display(
                    "[ERROR] State %0d duration=%0d expected=%0d",
                    expected_state, dut.note_duration, expected_duration
                );
            end
        end
    endtask

    // Check whether the piezo output is silent.
    task automatic check_silent;
        begin
            if ((piezo !== 1'b0) ||
                (piezo_n !== 1'b0) ||
                !tone_silent) begin

                error_count = error_count + 1;
                $display("[ERROR] Piezo is not silent");
            end
        end
    endtask

    initial begin
        clk         = 1'b0;
        rst_n       = 1'b0;
        en_steer    = 1'b0;
        too_fast    = 1'b0;
        batt_low    = 1'b0;
        error_count = 0;

        // Only reset once, as on the real board.
        repeat (4) @(posedge clk);
        check_silent();
        rst_n = 1'b1;

        // No input: remain in WAIT and remain silent.
        repeat (20) @(posedge clk);
        check_state(S_WAIT, 1);
        check_silent();

        // First test: wait the full repeat interval, then play Charge!.
        en_steer = 1'b1;

        check_note(S_G6, P_G6, D_23, REPEAT_LIMIT);
        check_note(S_C7, P_C7, D_23, D_23 + 100);
        check_note(S_E7, P_E7, D_23, D_23 + 100);
        check_note(S_G7, P_G7, D_23_PLUS_22, D_23_PLUS_22 + 100);
        check_note(S_E7_SHORT, P_E7, D_22, D_23_PLUS_22 + 100);
        check_note(S_G7_LONG, P_G7, D_24, D_22 + 100);
        check_state(S_WAIT, D_24 + 100);
        check_silent();

        // Complete a second Charge! cycle with en_steer still asserted.
        check_note(S_G6, P_G6, D_23, REPEAT_LIMIT);
        check_note(S_C7, P_C7, D_23, D_23 + 100);
        check_note(S_E7, P_E7, D_23, D_23 + 100);
        check_note(S_G7, P_G7, D_23_PLUS_22, D_23_PLUS_22 + 100);
        check_note(S_E7_SHORT, P_E7, D_22, D_23_PLUS_22 + 100);
        check_note(S_G7_LONG, P_G7, D_24, D_22 + 100);
        check_state(S_WAIT, D_24 + 100);
        check_silent();

        // Second test: too_fast is asserted together with the other inputs.
        // It must have priority and continuously play G6 -> C7 -> E7.
        en_steer = 1'b0;
        too_fast = 1'b1;
        batt_low = 1'b1;

        check_note(S_G6, P_G6, D_23, 10);
        check_note(S_C7, P_C7, D_23, D_23 + 100);
        check_note(S_E7, P_E7, D_23, D_23 + 100);
        check_note(S_G6, P_G6, D_23, D_23 + 100);

        // Third test: release too_fast and play the complete reverse fanfare.
        too_fast = 1'b0;

        check_note(S_G7_LONG, P_G7, D_24, D_23 + 100);
        check_note(S_E7_SHORT, P_E7, D_22, D_24 + 100);
        check_note(S_G7, P_G7, D_23_PLUS_22, D_22 + 100);
        check_note(S_E7, P_E7, D_23, D_23_PLUS_22 + 100);
        check_note(S_C7, P_C7, D_23, D_23 + 100);
        check_note(S_G6, P_G6, D_23, D_23 + 100);
        check_state(S_WAIT, D_23 + 100);
        check_silent();

        batt_low = 1'b0;

        // Final test report.
        $display("----------------------------------------");

        if (error_count == 0)
            $display("piezo_drv_tb: PASS (0 errors)");
        else
            $display("piezo_drv_tb: COMPLETE (%0d errors)", error_count);

        $display("----------------------------------------");

        $finish;
    end

endmodule
