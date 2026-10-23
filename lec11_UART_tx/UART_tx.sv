module UART_tx (
    input clk, rst_n, trmt,
    input [7:0] tx_data,
    output logic TX, tx_done
);

    // FSM
    typedef enum logic {
        IDLE,
        TRAN
    } state_t;

    state_t cs, ns;
    logic finished, load, transmitting;
    logic shift;
    logic [12:0] baud_cnt;

    always_ff @(posedge clk) begin
        if (!rst_n)
            cs <= IDLE;
        else
            cs <= ns;
    end

    always_comb begin
        ns = cs;
        load = 1'b0;
        transmitting = 1'b0;
        case (cs)
            IDLE: begin
                if (trmt) begin
                    ns = TRAN;
                    load = 1'b1;
                end
            end
            TRAN: begin
                transmitting = 1'b1;
                if (finished)
                    ns = IDLE;
            end
            default: ns = IDLE;
        endcase
    end

    // baud_cnt
    always_ff @(posedge clk) begin
        if (!rst_n)
            baud_cnt <= 13'd0;
        else begin
            if (load | shift)
                baud_cnt <= 13'd0;
            else if (transmitting)
                baud_cnt <= baud_cnt + 1;
        end
    end
    assign shift = (baud_cnt == 13'd5208);

    // bitcnt
    logic [3:0] bit_cnt;
    always_ff @(posedge clk) begin
        if (!rst_n)
            bit_cnt <= 4'd0;
        else begin
            if (load)
                bit_cnt <= 4'd0;
            else if (shift)
                bit_cnt <= bit_cnt + 1;
        end
    end
    assign finished = (bit_cnt == 4'd9);

    // TX
    logic [9:0] tx_shift_reg;
    always_ff @(posedge clk) begin
        if (!rst_n)
            tx_shift_reg <= 10'b1;
        else begin
            if (load)
                tx_shift_reg <= {1'b1, tx_data, 1'b0};
            else if (shift)
                tx_shift_reg <= tx_shift_reg >> 1;
        end
    end

    assign TX = (cs == IDLE) ? 1'b1 : tx_shift_reg[0];

    always_ff @(posedge clk) begin
        if (!rst_n)
            tx_done <= 1'b0;
        else begin
            if (load)
                tx_done <= 1'b0;
            else if (cs == TRAN && finished)
                tx_done <= 1'b1;
        end
    end
endmodule
