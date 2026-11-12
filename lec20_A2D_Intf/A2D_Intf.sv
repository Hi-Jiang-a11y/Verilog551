module A2D_intf (
    input logic clk,
    input logic rst_n,
    input logic nxt,
    output logic [11:0] lft_ld,
    output logic [11:0] rght_ld,
    output logic [11:0] steer_pot,
    output logic [11:0] batt,
    output logic SS_n,
    output logic SCLK,
    output logic MOSI,
    input logic MISO
);

// FSM states:
//   IDLE - wait for nxt
//   CNV  - 1st SPI transaction (sends channel to convert, response is junk)
//   WAIT - 1 clock with SS_n high between transactions
//   RD   - 2nd SPI transaction (shifts in conversion result)
typedef enum logic [1:0] {
    IDLE,
    CNV,
    WAIT,
    RD
} state_t;
state_t state;
state_t next_state;
logic update;   // store result & advance round robin counter
logic wrt;      // start an SPI transaction
logic spi_done;

// FSM transitions
always_comb begin
    next_state = state;
    update = 0;
    wrt = 0;
    case (state)
        IDLE: begin
            if (nxt) begin
                wrt = 1;
                next_state = CNV;
            end
        end
        CNV: begin
            if (spi_done) begin
                next_state = WAIT;
            end
        end
        WAIT: begin
            wrt = 1;
            next_state = RD;
        end
        RD: begin
            if (spi_done) begin
                update = 1;
                next_state = IDLE;
            end
        end
        default: next_state = IDLE;
    endcase
end

// update state on clock edge
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// round robin counter: 0 = left(0), 1 = right(4), 2 = steering(5), 3 = battery(6)
// advances only after the result has been stored
logic [1:0] counter;
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 2'b00;
    end else if (update) begin
        counter <= counter + 2'b01;
    end
end

// SPI transaction
logic [15:0] wt_data;
logic [15:0] rd_data;
SPI_main spi(
    .clk(clk),
    .rst_n(rst_n),
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .wrt(wrt),
    .wt_data(wt_data),
    .done(spi_done),
    .rd_data(rd_data)
);

// channel command: {2'b00, channel[2:0], 11'h000}
localparam logic [15:0] LEFT_LD_CHANNEL   = {2'b00, 3'd0, 11'h000}; // 16'h0000
localparam logic [15:0] RGHT_LD_CHANNEL   = {2'b00, 3'd4, 11'h000}; // 16'h2000
localparam logic [15:0] STEER_POT_CHANNEL = {2'b00, 3'd5, 11'h000}; // 16'h2800
localparam logic [15:0] BATT_CHANNEL      = {2'b00, 3'd6, 11'h000}; // 16'h3000
always_comb begin
    case (counter)
        2'b00: wt_data = LEFT_LD_CHANNEL;
        2'b01: wt_data = RGHT_LD_CHANNEL;
        2'b10: wt_data = STEER_POT_CHANNEL;
        default: wt_data = BATT_CHANNEL;
    endcase
end

// store result of the 2nd transaction into the register selected by counter
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lft_ld <= 12'h000;
        rght_ld <= 12'h000;
        steer_pot <= 12'h000;
        batt <= 12'h000;
    end else if (update) begin
        case (counter)
            2'b00: lft_ld <= rd_data[11:0];
            2'b01: rght_ld <= rd_data[11:0];
            2'b10: steer_pot <= rd_data[11:0];
            default: batt <= rd_data[11:0];
        endcase
    end
end

endmodule


/*
Signal Dir Description
clk,rst_n in 50MHz clock and active low asynch reset
nxt in Initiates A2D conversion on next measurand
lft_ld[11:0] out Result of last conversion on channel 0 (left load cell)
rght_ld[11:0] out Result of last conversion on channel 4 (right load cell)
steer_pot[11:0] out Result of last conversion on channel 5 (steering potentiometer)
batt[11:0] out Result of last conversion on channel 6 (battery voltage)
SPI Interface Out/in SS_n, SCLK, MOSI, MISO of a SPI interface. Comes from copy of SPI_main embedded into this unit.
*/
