module SPI_main (
    input logic clk,
    input logic rst_n,
    output logic SS_n,
    output logic SCLK,
    output logic MOSI,
    input logic MISO,
    input logic wrt,
    input logic [15:0] wt_data,
    output logic done,
    output logic [15:0] rd_data
);
    // SCLK generation
    logic ld_SCLK;
    localparam SCLK_div_init = 4'b1011;
    logic smpl;
    logic shft_imm;
    logic [3:0] SCLK_div_q;
    logic [3:0] SCLK_div_d;
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            SCLK_div_q <= SCLK_div_init;
        end
        else begin
            SCLK_div_q <= SCLK_div_d;
        end
    end
    assign SCLK = SCLK_div_q[3];
    assign SCLK_div_d = (ld_SCLK) ? SCLK_div_init : SCLK_div_q + 1;
    assign smpl = (SCLK_div_q == 4'b0111); // SCLK will rise on the next clock cycle
    assign shft_imm = (SCLK_div_q == 4'b1111); // SCLK will fall on the next clock cycle

    // shift register (MOSI) 16-bit for send and receive
    logic MISO_smpl_q;
    logic MISO_smpl_d;
    logic [15:0] shft_reg_q;
    logic [15:0] shft_reg_d;
    logic init; // internal signal for FSM
    logic shft;
    // MISO sampling DFF
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            MISO_smpl_q <= 1'b0;
        end
        else begin
            MISO_smpl_q <= MISO_smpl_d;
        end
    end
    assign MISO_smpl_d = (smpl) ? MISO : MISO_smpl_q;
    // shift register DFFs
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            shft_reg_q <= 16'b0;
        end
        else begin
            shft_reg_q <= shft_reg_d;
        end
    end
    assign MOSI = shft_reg_q[15];
    assign rd_data = shft_reg_q;
    // shft_reg_d mux
    always_comb begin
        case ({init, shft})
            2'b00: shft_reg_d = shft_reg_q;
            2'b01: shft_reg_d = {shft_reg_q[14:0], MISO_smpl_q};
            default: shft_reg_d = wt_data;
        endcase
    end
    // bit counter
    logic [3:0] post_shft;
    logic [3:0] bit_cntr_q;
    logic [3:0] bit_cntr_d;
    logic done15; // internal signal for FSM
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            bit_cntr_q <= 4'b0;
        end
        else begin
            bit_cntr_q <= bit_cntr_d;
        end
    end
    assign post_shft = (shft) ? bit_cntr_q + 1 : bit_cntr_q;
    assign bit_cntr_d = (init) ? 4'b0000 : post_shft;
    assign done15 = &bit_cntr_q; // bit_cntr_q == 4'b1111
    // FSM
    typedef enum logic [1:0] {IDLE, FRONT, SHIFT, BACK} state_t;
    state_t curr_state, next_state;
    logic set_done; // internal signal for FSM
    // FSM next state logic
    always_comb begin
        // defaults
        next_state = curr_state;
        shft = 1'b0;
        ld_SCLK = 1'b0;
        init = 1'b0;
        set_done = 1'b0;
        case (curr_state)
            IDLE: begin
                ld_SCLK = 1'b1;
                if (wrt) begin
                    init = 1'b1;
                    next_state = FRONT;
                end
            end
            FRONT: begin
                if (shft_imm) begin
                    next_state = SHIFT;
                end
            end
            SHIFT: begin
                shft = shft_imm;
                if (done15) begin
                    next_state = BACK;
                end
            end
            BACK: begin
                if (shft_imm) begin
                    shft = 1'b1;
                    ld_SCLK = 1'b1;
                    set_done = 1'b1;
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    // udpate FSM state
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            curr_state <= IDLE;
        end
        else begin
            curr_state <= next_state;
        end
    end
    // output logic
    // RSFF for SS_n output
    // init is clear, set_done is set
    logic SS_n_d;
    always_comb begin
        case ({set_done, init})
            2'b00: SS_n_d = SS_n;
            2'b01: SS_n_d = 1'b0;
            2'b10: SS_n_d = 1'b1;
            default: SS_n_d = 1'b1;
        endcase
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            SS_n <= 1'b1;
        end
        else begin
            SS_n <= SS_n_d;
        end
    end
    // RSFF for done output
    // init is clear, set_done is set
    logic done_d;
    always_comb begin
        case ({set_done, init})
            2'b00: done_d = done;
            2'b01: done_d = 1'b0;
            2'b10: done_d = 1'b1;
            default: done_d = 1'b0;
        endcase
    end
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            done <= 1'b0;
        end
        else begin
            done <= done_d;
        end
    end
endmodule

/*
clk, rst_n in 50MHz system clock and reset
SS_n, SCLK, MOSI,MISO 3-out, 1-in SPI protocol signals outlined earlier
wrt in A high for 1 clock period would initiate a SPI transaction
wt_data[15:0] in Data (command) being sent to inertial sensor.
done out Asserted when SPI transaction is complete. Should stay asserted till next wrt
rd_data[15:0] out Data from SPI secondary. For inertial sensor we will only ever use [7:0]
*/

// Claude Code (Opus 5.5) was used to help write this module
// It helped mainly with the FSM state transition logic
// This was good for learning since it explained the SPI protocol
// and how the FSM represented it.
