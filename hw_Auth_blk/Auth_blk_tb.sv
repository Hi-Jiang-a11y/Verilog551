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

        // OFF ignores S and unrelated bytes, but remains able to accept G.
        send_byte(8'h53);
        check_power(1'b0, "S while off is ignored");
        send_byte(8'h41);
        check_power(1'b0, "invalid byte while off is ignored");

        // G authorizes the rider. A repeated G is harmless.
        send_byte(8'h47);
        check_power(1'b1, "G changes OFF to ON");
        send_byte(8'h47);
        check_power(1'b1, "repeated G while ON is harmless");

        // Disconnect while the rider is present enters STANDBY and keeps
        // power on. A second S does not change that state.
        rider_off = 1'b0;
        send_byte(8'h53);
        check_power(1'b1, "S with rider present enters standby");
        send_byte(8'h53);
        check_power(1'b1, "S in standby keeps power on");

        // Rider leaving later shuts down without another UART byte.
        rider_off = 1'b1;
        check_power(1'b0, "rider leaving standby shuts down");

        // G is accepted again from OFF, even if rider_off is high.
        send_byte(8'h47);
        check_power(1'b1, "G re-authorizes after standby shutdown");

        // In ON, rider_off alone must not shut down; S is required.
        rider_off = 1'b1;
        check_power(1'b1, "rider_off alone does not shut down ON");
        send_byte(8'h53);
        check_power(1'b0, "S with rider off changes ON to OFF");

        // Verify the STANDBY-to-ON arc and distinguish it from ON.
        rider_off = 1'b0;
        send_byte(8'h47);
        check_power(1'b1, "G starts a second ON session");
        send_byte(8'h53);
        check_power(1'b1, "second disconnect enters standby");
        send_byte(8'h47);
        check_power(1'b1, "G from standby returns to ON");
        rider_off = 1'b1;
        check_power(1'b1, "rider_off alone still leaves ON powered");
        send_byte(8'h53);
        check_power(1'b0, "final S with rider off powers down");

        if (errors == 0)
            $display("\nAUTH_BLK TEST PASSED");
        else
            $display("\nAUTH_BLK TEST FAILED: %0d error(s)", errors);
        $finish;
    end

endmodule
