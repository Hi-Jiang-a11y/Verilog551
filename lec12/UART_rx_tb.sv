`timescale 1ns/1ps

module UART_rx_tb;

    localparam int CLK_PERIOD   = 10;
    localparam int CLKS_PER_BIT = 5209;
    localparam int BIT_PERIOD   = CLK_PERIOD * CLKS_PER_BIT;
    localparam int INTER_BYTE_IDLE_BITS = 2;

    logic       clk;
    logic       rst_n;
    logic       RX;
    logic       clr_rdy;
    logic [7:0] rx_data;
    logic       rdy;

    UART_rx dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .RX      (RX),
        .clr_rdy (clr_rdy),
        .rx_data (rx_data),
        .rdy     (rdy)
    );

    initial clk = 1'b0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    task automatic send_uart_byte(input logic [7:0] data);
        RX = 1'b0;
        #(BIT_PERIOD);

        for (int i = 0; i < 8; i++) begin
            RX = data[i];
            #(BIT_PERIOD);
        end

        RX = 1'b1;
        #(BIT_PERIOD);
    endtask

    task automatic wait_for_ready;
        int timeout_cycles;

        timeout_cycles = CLKS_PER_BIT * 12;
        while ((rdy !== 1'b1) && (timeout_cycles > 0)) begin
            @(posedge clk);
            timeout_cycles--;
        end

        if (rdy !== 1'b1)
            $fatal(1, "Timeout waiting for rdy");
    endtask

    task automatic check_byte(input logic [7:0] expected);
        send_uart_byte(expected);
        wait_for_ready();

        if (rx_data !== expected)
            $fatal(1, "RX mismatch: expected 0x%02h, got 0x%02h",
                   expected, rx_data);

        $display("[%0t] PASS: received 0x%02h", $time, rx_data);

        repeat (3) begin
            @(negedge clk);
            if (rdy !== 1'b1)
                $fatal(1, "rdy dropped before clr_rdy (data 0x%02h)", expected);
            if (rx_data !== expected)
                $fatal(1, "rx_data changed while rdy was asserted");
        end

        @(negedge clk);
        clr_rdy = 1'b1;
        @(negedge clk);
        clr_rdy = 1'b0;

        if (rdy !== 1'b0)
            $fatal(1, "rdy did not clear after clr_rdy pulse");

        @(posedge clk);
        #1;
        if (rdy !== 1'b0)
            $fatal(1, "rdy re-asserted without a new received byte");

        if (rx_data !== expected)
            $fatal(1, "rx_data changed when clr_rdy was asserted");

        RX = 1'b1;
        repeat (INTER_BYTE_IDLE_BITS * CLKS_PER_BIT) begin
            @(posedge clk);
            if (rdy !== 1'b0)
                $fatal(1, "rdy asserted during inter-byte idle time");
        end
    endtask

    task automatic check_byte_without_clear(input logic [7:0] expected);
        send_uart_byte(expected);
        wait_for_ready();

        if (rx_data !== expected)
            $fatal(1, "RX mismatch: expected 0x%02h, got 0x%02h",
                   expected, rx_data);

        $display("[%0t] PASS: received 0x%02h (clr_rdy not asserted)",
                 $time, rx_data);

        repeat (INTER_BYTE_IDLE_BITS * CLKS_PER_BIT) begin
            @(posedge clk);
            if (rdy !== 1'b1)
                $fatal(1, "rdy dropped while clr_rdy was not asserted");
            if (rx_data !== expected)
                $fatal(1, "rx_data changed while clr_rdy was not asserted");
        end
    endtask

    initial begin
        rst_n   = 1'b0;
        RX      = 1'b1;
        clr_rdy = 1'b0;

        repeat (5) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        repeat (3) @(posedge clk);

        if (rdy !== 1'b0)
            $fatal(1, "rdy was not low after reset");

        check_byte_without_clear(8'b1001_0101);

        check_byte(8'b0110_1010);
        check_byte(8'b1100_0110);
        check_byte(8'b0011_1001);

        $display("[%0t] All UART_rx tests passed", $time);
        $stop;
    end

endmodule
