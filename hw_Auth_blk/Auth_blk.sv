module Auth_blk (
    input clk, rst_n,
    input  RX,
    input  rider_off,
    output pwr_up
);

    logic clr_rx_rdy;
    logic rx_rdy;
    logic [7:0] rx_data;

    UART_rx uart (
        .clk(clk), .rst_n(rst_n),
        .clr_rdy(clr_rx_rdy),
        .RX(RX),
        .rx_data(rx_data),
        .rdy(rx_rdy)
    );

    typedef enum logic {
        ENABLE, DISABLE
    } state_t;

    state_t cs, ns;

    always_ff @(posedge clk) begin
        if (!rst_n)
            cs <= DISABLE;
        else
            cs <= ns;
    end

    always_comb begin
        ns = cs;
        clr_rx_rdy = 0;
        case (cs)
            DISABLE: begin
                if (rx_rdy & (rx_data == 8'h47)) begin
                    clr_rx_rdy = 1;
                    ns = ENABLE;
                end
            end ENABLE: begin
                if (rx_rdy & (rx_data == 8'h53) & rider_off) begin
                    clr_rx_rdy = 1;
                    ns = DISABLE;
                end
            end
        endcase
    end

    assign pwr_up = (cs == ENABLE);

endmodule
