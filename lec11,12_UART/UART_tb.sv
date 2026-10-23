`timescale 1ns/1ps

module UART_tb;

    localparam int CLK_PERIOD         = 10;
    localparam int CLKS_PER_BIT       = 5209;
    localparam int INTER_BYTE_BITS    = 2;
    localparam int TIMEOUT_CYCLES     = CLKS_PER_BIT * 12;

    logic       clk;
    logic       rst_n;
    logic       trmt;
    logic [7:0] tx_data;
    logic       clr_rdy;
    wire  [7:0] rx_data;
    wire        rdy;
    wire        tx_done;
    wire        TX;

    UART dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .trmt    (trmt),
        .tx_data (tx_data),
        .clr_rdy (clr_rdy),
        .rx_data (rx_data),
        .rdy     (rdy),
        .tx_done (tx_done),
        .TX      (TX)
    );

    initial clk = 1'b0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    task automatic wait_for_tx_done;
        int timeout;
        timeout = TIMEOUT_CYCLES;
        while ((tx_done !== 1'b1) && (timeout > 0)) begin
            @(posedge clk);
            timeout--;
        end
        if (tx_done !== 1'b1)
            $fatal(1, "Timeout waiting for tx_done=1");
    endtask

    task automatic wait_for_rdy;
        int timeout;
        timeout = TIMEOUT_CYCLES;
        while ((rdy !== 1'b1) && (timeout > 0)) begin
            @(posedge clk);
            timeout--;
        end
        if (rdy !== 1'b1)
            $fatal(1, "Timeout waiting for rdy=1");
    endtask

    task automatic transmit_byte(input logic [7:0] data);
        @(negedge clk);
        tx_data = data;
        trmt    = 1'b1;
        @(negedge clk);
        trmt    = 1'b0;

        wait_for_tx_done();
        wait_for_rdy();

        if (rx_data !== data)
            $fatal(1, "Loopback mismatch: expected 0x%02h, got 0x%02h",
                   data, rx_data);

        $display("[%0t] PASS: TX/RX loopback 0x%02h", $time, rx_data);
    endtask

    task automatic clear_ready;
        @(negedge clk);
        clr_rdy = 1'b1;
        @(negedge clk);
        clr_rdy = 1'b0;
        #1;
        if (rdy !== 1'b0)
            $fatal(1, "rdy did not clear after clr_rdy");
    endtask

    initial begin
        rst_n   = 1'b0;
        trmt    = 1'b0;
        tx_data = 8'h00;
        clr_rdy = 1'b0;

        repeat (5) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        if (rdy !== 1'b0 || tx_done !== 1'b0 || TX !== 1'b1)
            $fatal(1, "Unexpected outputs after reset");

        transmit_byte(8'b1001_0101);

        repeat (INTER_BYTE_BITS * CLKS_PER_BIT) begin
            @(posedge clk);
            if (rdy !== 1'b1)
                $fatal(1, "rdy dropped before clr_rdy");
            if (rx_data !== 8'b1001_0101)
                $fatal(1, "rx_data changed before clr_rdy");
        end
        clear_ready();

        repeat (INTER_BYTE_BITS * CLKS_PER_BIT) @(posedge clk);

        transmit_byte(8'b0110_1010);
        clear_ready();
        repeat (INTER_BYTE_BITS * CLKS_PER_BIT) @(posedge clk);

        transmit_byte(8'b1100_0110);
        clear_ready();

        $display("[%0t] All UART loopback tests passed", $time);
        $finish;
    end

endmodule
