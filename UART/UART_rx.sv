module UART_rx (
    input clk, rst_n, RX, clr_rdy,
    output logic [7:0] rx_data,
    output logic rdy
);

    logic RX_meta, RX_sync, RX_sync_d;
    logic RX_fall;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            RX_meta <= 1'b1;
            RX_sync <= 1'b1;
            RX_sync_d <= 1'b1;
        end else begin
            RX_meta <= RX;
            RX_sync <= RX_meta;
            RX_sync_d <= RX_sync;
        end
    end
    assign RX_fall = RX_sync_d & ~RX_sync;

    // FSM
    typedef enum logic {
        IDLE,
        REC
    } state_t;

    state_t cs, ns;

    always_ff @(posedge clk) begin
        if (!rst_n)
            cs <= IDLE;
        else
            cs <= ns;
    end

    logic finished, start, receiving;
    always_comb begin
        start = 1'b0;
        receiving = 1'b0;
        ns = cs;
        case (cs)
            IDLE: begin
                if (RX_fall) begin
                    ns = REC;
                    start = 1'b1;
                end
            end
            REC: begin
                receiving = 1'b1;
                if (finished)
                    ns = IDLE;
            end
        endcase
    end

    // baud_cnt
    logic [12:0] baud_cnt;
    logic shift;
    always_ff @(posedge clk) begin
        if (!rst_n)
            baud_cnt <= 13'd5208;
        else begin
            if (start | shift)
                baud_cnt <= (start) ? 2604 : 5208;
            else if (receiving)
                baud_cnt <= baud_cnt - 1;
        end
    end
    assign shift = (baud_cnt == 13'd0);

    // bit_cnt
    logic [3:0] bit_cnt;
    always_ff @(posedge clk) begin
        if (!rst_n)
            bit_cnt <= 4'd0;
        else begin
            if (start)
                bit_cnt <= 4'd0;
            else if (shift)
                bit_cnt = bit_cnt + 1;
        end
    end
    assign finished = (bit_cnt == 4'd10);

    // RX
    logic [8:0] rx_shift_reg;
    always_ff @(posedge clk) begin
        if (!rst_n)
            rx_shift_reg <= 9'd0;
        else begin
            if (shift)
                rx_shift_reg <= {RX_sync_d, {rx_shift_reg[8:1]}};
        end
    end
    assign rx_data = rx_shift_reg[7:0];

    // rdy
    always_ff @(posedge clk) begin
        if (!rst_n)
            rdy <= 1'd0;
        else if (clr_rdy | start)
            rdy <= 1'd0;
        else if ((cs == REC) & finished)
            rdy <= 1'd1;
    end
endmodule
