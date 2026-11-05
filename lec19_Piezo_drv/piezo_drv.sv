module piezo_drv #(
    parameter bit FAST_SIM = 1'b1
) (
    input  logic clk, rst_n,
    input  logic en_steer, too_fast, batt_low,
    output logic piezo, piezo_n
);
    typedef enum logic [2:0] { WAIT, G6, C7, E7, G7, E7_SHORT, G7_LONG } state_t;

    localparam int unsigned REPEAT_TICKS = FAST_SIM ? 2_343_750 : 150_000_000;
    localparam int unsigned DUR_23 = FAST_SIM ? 131_072 : 8_388_608;
    localparam int unsigned DUR_22 = FAST_SIM ? 65_536 : 4_194_304;
    localparam int unsigned DUR_23_PLUS_22 = FAST_SIM ? 196_608 : 12_582_912;
    localparam int unsigned DUR_24 = FAST_SIM ? 262_144 : 16_777_216;
    localparam int unsigned HALF_G6 = FAST_SIM ? 249 : 15_944;
    localparam int unsigned HALF_C7 = FAST_SIM ? 187 : 11_945;
    localparam int unsigned HALF_E7 = FAST_SIM ? 148 : 9_481;
    localparam int unsigned HALF_G7 = FAST_SIM ? 124 : 7_972;

    state_t cs, ns;
    logic [27:0] repeat_count;
    logic [24:0] note_count, note_duration;
    logic [14:0] tone_count, half_period;
    logic note_done, repeat_done;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cs <= WAIT;
        else
            cs <= ns;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            repeat_count <= '0;
        else if (cs != WAIT)
            repeat_count <= '0;
        else if (repeat_count < REPEAT_TICKS)
            repeat_count <= repeat_count + 1'b1;
    end
    assign repeat_done = (repeat_count >= REPEAT_TICKS);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            note_count <= '0;
        else if (cs == WAIT || note_done)
            note_count <= '0;
        else
            note_count <= note_count + 1'b1;
    end
    assign note_done = (cs != WAIT) && (note_count >= note_duration - 1'b1);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tone_count <= '0;
        else if (cs == WAIT || tone_count >= half_period - 1'b1)
            tone_count <= '0;
        else
            tone_count <= tone_count + 1'b1;
    end

    always_comb begin
        ns = cs;
        note_duration = DUR_23;
        half_period = HALF_G6;
        case (cs)
            WAIT: begin
                note_duration = DUR_23;
                half_period = HALF_G6;
                if (too_fast)
                    ns = G6;
                else if (batt_low)
                    ns = E7;
                else if (en_steer && repeat_done)
                    ns = G6;
            end G6: begin
                note_duration = DUR_23;
                half_period = HALF_G6;
                if (note_done) begin
                    if (too_fast)
                        ns = C7;
                    else if (batt_low)
                        ns = WAIT;
                    else
                        ns = C7;
                end
            end C7: begin
                note_duration = DUR_23;
                half_period = HALF_C7;
                if (note_done) begin
                    if (too_fast)
                        ns = E7;
                    else if (batt_low)
                        ns = G6;
                    else
                        ns = E7;
                end
            end E7: begin
                note_duration = DUR_23;
                half_period = HALF_E7;
                if (note_done) begin
                    if (too_fast)
                        ns = G6;
                    else if (batt_low)
                        ns = C7;
                    else
                        ns = G7;
                end
            end G7: begin
                note_duration = DUR_23_PLUS_22;
                half_period = HALF_G7;
                if (note_done) begin
                    if (too_fast)
                        ns = G6;
                    else
                        ns = E7_SHORT;
                end
            end E7_SHORT: begin
                note_duration = DUR_22;
                half_period = HALF_E7;
                if (note_done) begin
                    if (too_fast)
                        ns = G6;
                    else
                        ns = G7_LONG;
                end
            end G7_LONG: begin
                note_duration = DUR_24;
                half_period = HALF_G7;
                if (note_done) begin
                    if (too_fast)
                        ns = G6;
                    else
                        ns = WAIT;
                end
            end default: begin
                ns = WAIT;
                note_duration = DUR_23;
                half_period = HALF_G6;
            end
        endcase
    end

    assign piezo = (cs != WAIT) ? (tone_count < half_period / 2) : 1'b0;
    assign piezo_n = (cs != WAIT) ? ~piezo : 1'b0;

endmodule
