`timescale 1ns/1ps

module tb_UART_tx;

    localparam int CLK_PERIOD_NS = 20;   // 50 MHz
    // With baud_cnt == 13'd5208, the current DUT holds each bit for
    // 5209 clock cycles.  If the DUT compares against 5207 instead,
    // change this value to 5208.
    localparam int BIT_CYCLES    = 5209;

    logic       clk;
    logic       rst_n;
    logic       trmt;
    logic [7:0] tx_data;
    logic       TX;
    logic       tx_done;

    UART_tx dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .trmt    (trmt),
        .tx_data (tx_data),
        .TX      (TX),
        .tx_done (tx_done)
    );

    always #(CLK_PERIOD_NS/2) clk = ~clk;

    task automatic send_byte(input logic [7:0] data);
        begin
            @(negedge clk);
            tx_data = data;
            trmt    = 1'b1;
            @(negedge clk);
            trmt    = 1'b0;
            repeat (10 * BIT_CYCLES) @(posedge clk);
        end
    endtask

    task automatic idle_bits(input int unsigned count);
        begin
            repeat (count * BIT_CYCLES) @(posedge clk);
        end
    endtask

    task automatic reset_while_transmitting(input logic [7:0] data,
                                             input int unsigned bit_offset);
        begin
            @(negedge clk);
            tx_data = data;
            trmt    = 1'b1;
            @(negedge clk);
            trmt    = 1'b0;
            repeat (bit_offset * BIT_CYCLES + BIT_CYCLES/2) @(posedge clk);
            @(negedge clk);
            rst_n = 1'b0;
            repeat (2) @(posedge clk);
            @(negedge clk);
            rst_n = 1'b1;
        end
    endtask

    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, tb_UART_tx);

        clk     = 1'b0;
        rst_n   = 1'b0;
        trmt    = 1'b0;
        tx_data = 8'h00;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        @(negedge clk);

        send_byte(8'h00);
        idle_bits(2);
        send_byte(8'hFF);
        idle_bits(2);
        send_byte(8'h55);
        idle_bits(2);
        send_byte(8'hAA);

        // Immediate restart after a completed STOP bit.
        send_byte(8'hC3);

        // Reset in the middle of a frame, then wait before recovering.
        idle_bits(2);
        reset_while_transmitting(8'h96, 3);
        idle_bits(2);
        send_byte(8'h5A);

        // Reset while idle, followed by a delayed transmission.
        idle_bits(2);
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        idle_bits(2);
        send_byte(8'h7E);

        idle_bits(2);
        send_byte(8'h81);

        $finish;
    end

endmodule
