`timescale 1ns/1ps

module PID_Math_wave_tb;

    logic signed [15:0] ptch;
    logic signed [15:0] ptch_rt;
    logic signed [17:0] integrator;
    logic        [11:0] PID_cntrl;

    PID_Math dut (
        .ptch(ptch),
        .ptch_rt(ptch_rt),
        .integrator(integrator),
        .PID_cntrl(PID_cntrl)
    );

    integer i;

    initial begin
        $dumpfile("PID_Math_tb.vcd");
        $dumpvars(0, PID_Math_wave_tb);

        for (i = 0; i <= 4096; i = i + 1) begin
            ptch = -256 + i * (255 + 256) / 4096;

            if (((i / 1024) % 2) == 0)
                integrator = -16384 + (i % 1024) * (16383 + 16384) / 1024;
            else
                integrator = 16383 - (i % 1024) * (16383 + 16384) / 1024;

            if (((i / 512) % 2) == 0)
                ptch_rt = 4095 - (i % 512) * (4095 + 4096) / 512;
            else
                ptch_rt = -4096 + (i % 512) * (4095 + 4096) / 512;

            #1;
        end
        $stop;
    end
endmodule
