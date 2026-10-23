module UART (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       trmt,
    input  logic [7:0] tx_data,
    input  logic       clr_rdy,
    output logic [7:0] rx_data,
    output logic       rdy,
    output logic       tx_done,
    output logic       TX
);

    // Internal loopback connection: transmitted serial data is received by
    // the UART receiver on the same clock and baud-rate domain.
    UART_tx tx_i (
        .clk     (clk),
        .rst_n   (rst_n),
        .trmt    (trmt),
        .tx_data (tx_data),
        .TX      (TX),
        .tx_done (tx_done)
    );

    UART_rx rx_i (
        .clk     (clk),
        .rst_n   (rst_n),
        .RX      (TX),
        .clr_rdy (clr_rdy),
        .rx_data (rx_data),
        .rdy     (rdy)
    );

endmodule
