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

    typedef enum logic [1:0] {
        OFF,
        ON,
        STANDBY
    } state_t;

    state_t cs, ns;

    always_ff @(posedge clk) begin
        if (!rst_n)
            cs <= OFF;
        else
            cs <= ns;
    end

    always_comb begin
        ns = cs;
        clr_rx_rdy = rx_rdy;
        case (cs)
            OFF: begin
                if (rx_rdy && (rx_data == 8'h47))
                    ns = ON;
            end
            ON: begin
                if (rx_rdy && (rx_data == 8'h53)) begin
                    if (rider_off)
                        ns = OFF;
                    else
                        ns = STANDBY;
                end
            end
            STANDBY: begin
                if (rider_off)
                    ns = OFF;
                else if (rx_rdy && (rx_data == 8'h47))
                    ns = ON;
            end
            default: ns = OFF;
        endcase
    end

    assign pwr_up = (cs != OFF);

endmodule
