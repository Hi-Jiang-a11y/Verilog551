module balance_cntrl_chk_tb ();

    localparam int NUM_VECTORS = 1500;

    logic clk;
    logic rst_n, vld, rider_off, pwr_up, en_steer;
    logic [15:0] ptch, ptch_rt;
    logic [17:0] integrator;
    logic [11:0] steer_pot;
    logic signed [11:0] lft_spd, rght_spd;
    logic too_fast;

    logic [48:0] stim_mem [0:NUM_VECTORS-1];
    logic [24:0] resp_mem [0:NUM_VECTORS-1];

    assign integrator = 18'h00000;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    balance_cntrl #(.fast_sim(1'b1)) dut_main (
        .clk        (clk),
        .rst_n      (rst_n),
        .vld        (vld),
        .rider_off  (rider_off),
        .ptch       (ptch),
        .ptch_rt    (ptch_rt),
        .integrator (integrator),
        .pwr_up     (pwr_up),
        .en_steer   (en_steer),
        .steer_pot  (steer_pot),
        .lft_spd    (lft_spd),
        .rght_spd   (rght_spd),
        .too_fast   (too_fast)
    );

    initial begin
        $readmemh("balance_cntrl_stim.hex", stim_mem);
        $readmemh("balance_cntrl_resp.hex", resp_mem);
        force dut_main.ss_tmr = 8'hFF;

        rst_n = 1'b0;
        vld = 1'b0;
        rider_off = 1'b0;
        ptch = 16'h0000;
        ptch_rt = 16'h0000;
        pwr_up = 1'b0;
        en_steer = 1'b0;
        steer_pot = 12'h000;
        errors = 0;

        integer vec;
        integer errors;

        for (vec = 0; vec < NUM_VECTORS; vec = vec + 1) begin
            rst_n = stim_mem[vec][48];
            vld = stim_mem[vec][47];
            ptch = stim_mem[vec][46:31];
            ptch_rt = stim_mem[vec][30:15];
            pwr_up = stim_mem[vec][14];
            rider_off = stim_mem[vec][13];
            steer_pot = stim_mem[vec][12:1];
            en_steer = stim_mem[vec][0];

            @(posedge clk);
            #1;
            if ({lft_spd, rght_spd, too_fast} !== resp_mem[vec]) begin
                errors = errors + 1;
                $display("ERROR vector %0d: got %h expected %h",
                         vec, {lft_spd, rght_spd, too_fast}, resp_mem[vec]);
            end
        end

        if (errors == 0)
            $display("PASS!", NUM_VECTORS);
        else
            $display("FAIL: %0d of %0d", errors, NUM_VECTORS);
        $finish;
    end

endmodule
