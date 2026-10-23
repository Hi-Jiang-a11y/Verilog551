module SPI_main (
    input clk, rst_n, wrt,
    input [15:0] wrt_data,
    output logic done,
    output logic [15:0] rd_data,
    input MISO,
    output logic SS_n, SCLK, MOSI
);

logic shft, init, ld_SCLK, set_done;
logic [3:0] bit_cntr;
logic done15;
logic [3:0] SCLK_div;
logic smpl, shft_imm;

typedef enum logic [1:0] {
    IDLE,
    FRONT_P,
    TRANS,
    BACK_P
} state_t;

state_t cs, ns;

always_ff @(posedge clk) begin
    if (!rst_n)
        cs <= IDLE;
    else
        cs <= ns;
end

always_comb begin
    ns       = cs;
    init     = 1'b0;
    shft     = 1'b0;
    ld_SCLK  = 1'b0;
    set_done = 1'b0;

    case (cs)
        IDLE: begin
            ld_SCLK = 1'b1;
            if (wrt) begin
                ns   = FRONT_P;
                init = 1'b1;
            end
        end

        FRONT_P: begin
            if (shft_imm)
                ns = TRANS;
        end

        TRANS: begin
            shft = shft_imm;
            if (done15)
                ns = BACK_P;
        end

        BACK_P: begin
            if (shft_imm) begin
                shft     = 1'b1;
                ld_SCLK  = 1'b1;
                set_done = 1'b1;
                ns       = IDLE;
            end
        end

        default: begin
            ns = IDLE;
        end
    endcase
end

// bit counter
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bit_cntr <= 4'd0;
    else if (init)
        bit_cntr <= 4'd0;
    else if (shft)
        bit_cntr <= bit_cntr + 1'b1;
end
assign done15 = &bit_cntr;

// SCLK
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        SCLK_div <= 4'b1011;
    else if (ld_SCLK)
        SCLK_div <= 4'b1011;
    else
        SCLK_div <= SCLK_div + 1'b1;
end
assign SCLK = SCLK_div[3];
assign smpl = (SCLK_div == 4'b0111);
assign shft_imm = (SCLK_div == 4'b1111);

// shift register
logic MISO_smpl;
logic [15:0] shft_reg;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        MISO_smpl <= 1'b0;
    else if (smpl)
        MISO_smpl <= MISO;
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        shft_reg <= 16'd0;
    else if (init)
        shft_reg <= wrt_data;
    else if (shft)
        shft_reg <= {shft_reg[14:0], MISO_smpl};
end
assign MOSI = shft_reg[15];

// done
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        done    <= 1'b0;
        rd_data <= 16'd0;
    end else if (init) begin
        done <= 1'b0;
    end else if (set_done) begin
        done    <= 1'b1;
        rd_data <= {shft_reg[14:0], MISO_smpl};
    end
end

// SS_n
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        SS_n <= 1'b1;
    else if (init)
        SS_n <= 1'b0;
    else if (set_done)
        SS_n <= 1'b1;
end

endmodule
