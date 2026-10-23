module sync_fifo #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 16  // always a power of 2, >= 2
)(
    input logic clk,
    input logic rst_n,  // asynchronous, active-low
    input logic wr_en,
    input logic [WIDTH-1:0] wr_data,
    input logic rd_en,
    output logic [WIDTH-1:0] rd_data,
    output logic full,
    output logic empty,
    output logic [$clog2(DEPTH+1)-1:0] count,
    output logic overflow,  // 1-cycle pulse
    output logic underflow  // 1-cycle pulse
);
    localparam int PTR_WIDTH = $clog2(DEPTH);
    logic [WIDTH-1:0] memory [0:DEPTH-1];
    logic [PTR_WIDTH-1:0] wr_ptr, rd_ptr;
    logic do_read, do_write;

    assign empty = (count == 0);
    assign full = (count == DEPTH);
    assign do_read = rd_en && !empty;
    // A read frees a slot on this edge, even when the FIFO starts full.
    assign do_write = wr_en && (!full || do_read);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            count <= '0;
            rd_data <= '0;
            overflow <= 1'b0;
            underflow <= 1'b0;
        end else begin
            overflow <= wr_en && !do_write;
            underflow <= rd_en && !do_read;

            if (do_write) begin
                memory[wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if (do_read) begin
                rd_data <= memory[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end

            case ({do_write, do_read})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: ;
            endcase
        end
    end

endmodule