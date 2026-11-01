`timescale 1ns/1ps

module Auth_blk_tb;

    logic clk, rst_n;
    logic RX;
    logic rider_off;
    logic pwr_up;
    logic trmt;
    logic [7:0] tx_data;
    logic tx_done;
    integer errors;

    Auth_blk dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .RX         (RX),
        .pwr_up     (pwr_up),
        .rider_off  (rider_off)
    );

    UART_tx uart_tx (
        .clk        (clk),
        .rst_n      (rst_n),
        .trmt       (trmt),
        .tx_data    (tx_data),
        .TX         (RX),
        .tx_done    (tx_done)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic send_byte(input logic [7:0] data);
        begin
            @(negedge clk);
            tx_data = data;
            trmt = 1'b1;
            @(negedge clk);
            trmt = 1'b0;
            @(posedge tx_done);

            wait (dut.rx_rdy === 1'b1);
            @(posedge clk);
            @(negedge clk);
        end
    endtask

    task automatic check_power(input logic expected, input string description);
        begin
            @(negedge clk);
            if (pwr_up !== expected) begin
                $error("%s: expected pwr_up=%0b, observed %0b at %0t ns",
                       description, expected, pwr_up, $time);
                errors = errors + 1;
            end else begin
                $display("PASS: %s (pwr_up=%0b)", description, pwr_up);
            end
        end
    endtask

    initial begin
        errors = 0;
        rst_n = 1'b0;
        rider_off = 1'b0;
        trmt = 1'b0;
        tx_data = 8'h00;

        repeat (4) @(negedge clk);
        check_power(1'b0, "reset holds disabled");
        rst_n = 1'b1;

        send_byte(8'h53);
        check_power(1'b0, "S while disabled is ignored");
        send_byte(8'h41);
        check_power(1'b0, "unrecognized character is ignored");

        send_byte(8'h47);
        check_power(1'b1, "G enables authentication block");
        send_byte(8'h47);
        check_power(1'b1, "G while enabled leaves block enabled");

        rider_off = 1'b0;
        send_byte(8'h53);
        check_power(1'b1, "S with rider present keeps power on");

        rider_off = 1'b1;
        send_byte(8'h53);
        check_power(1'b0, "S with rider off disables block");
        send_byte(8'h53);
        check_power(1'b0, "S after shutdown remains disabled");

        rider_off = 1'b0;
        send_byte(8'h47);
        check_power(1'b1, "a new G re-enables block");

        if (errors == 0)
            $display("\nAUTH_BLK TEST PASSED");
        else
            $display("\nAUTH_BLK TEST FAILED: %0d error(s)", errors);
        $finish;
    end

endmodule
