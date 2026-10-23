module SPI_main_tb ();
    logic clk, rst_n, wrt, done, SS_n, SCLK, MOSI, MISO, INT;
    logic [15:0] wt_data, rd_data;

    initial clk = 1'b0;
    always #10 clk = ~clk;

    SPI_main dut_main (
        .clk (clk), .rst_n (rst_n), .wrt (wrt), .done (done),
        .rd_data (rd_data), .wrt_data (wt_data),
        .SS_n (SS_n), .SCLK (SCLK), .MOSI (MOSI), .MISO (MISO)
    );
    SPI_iNEMO1 dut_sensor (
        .SS_n (SS_n), .SCLK (SCLK), .MISO (MISO), .MOSI (MOSI),
        .INT (INT)
    );

    // Send one 16-bit SPI transaction and wait for SPI_main to finish.
    task automatic spi_transaction(
        input  logic [15:0] tx_data,
        output logic [15:0] rx_data
    );
        integer cycles;
        begin
            @(negedge clk);
            wt_data = tx_data;
            wrt = 1'b1;

            @(negedge clk);
            wrt = 1'b0;

            cycles = 0;
            while ((done !== 1'b1) && (cycles < 1000)) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (done !== 1'b1)
                $fatal(1, "Timed out waiting for SPI transaction completion");

            rx_data = rd_data;

            if (SS_n !== 1'b1)
                $fatal(1, "SS_n did not return high after transaction");
        end
    endtask

    // Wait for a new sensor reading, with a timeout for a broken design.
    task automatic wait_for_int;
        integer cycles;
        begin
            cycles = 0;
            while ((INT !== 1'b1) && (cycles < 30000)) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (INT !== 1'b1)
                $fatal(1, "Timed out waiting for INT");
        end
    endtask

    task automatic check_byte(
        input logic [7:0] expected,
        input logic [15:0] actual,
        input [127:0] name
    );
        begin
            if (actual[7:0] !== expected)
                $fatal(1, "%s failed: expected %h, got %h",
                       name, expected, actual[7:0]);
            else
                $display("PASS: %s = %h", name, actual[7:0]);
        end
    endtask

    logic [15:0] rx;

    initial begin
        wt_data = 16'h0000;
        wrt = 1'b0;
        rst_n = 1'b0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        // WHO_AM_I: read register 0x0f, which must return 0x6a.
        spi_transaction(16'h8f00, rx);
        check_byte(8'h6a, rx, "WHO_AM_I");

        // Enable the sensor interrupt generation.
        spi_transaction(16'h0d02, rx);
        if (dut_sensor.NEMO_setup !== 1'b1)
            $fatal(1, "NEMO_setup was not asserted after writing INT config");

        // The first interrupt indicates that inert_data[0] is available.
        wait_for_int();

        // Row 0: pitch is 0x5663, so pitch low is 0x63.
        spi_transaction(16'ha200, rx);
        check_byte(8'h63, rx, "row0 pitchL");
        wait (!INT);

        // The next interrupt advances the sensor to inert_data[1].
        wait_for_int();

        // Row 1: 8465_5212_e301_cd0d_f176_cd3d.
        spi_transaction(16'ha300, rx);
        check_byte(8'hcd, rx, "row1 pitchH");

        spi_transaction(16'ha600, rx);
        check_byte(8'h3d, rx, "row1 yawL");

        spi_transaction(16'ha700, rx);
        check_byte(8'hcd, rx, "row1 yawH");

        $display("All SPI_main checks passed.");
        $finish;
    end

endmodule
