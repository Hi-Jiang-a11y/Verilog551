module piezo_drv #(
    parameter bit FAST_SIM = 1'b1
) (
    input  logic clk, rst_n,
    input  logic en_steer, too_fast, batt_low,
    output logic piezo, piezo_n
);
    typedef enum logic [2:0] { WAIT, G6, C7, E7, G7, E7_SHORT, G7_LONG } state_t;

    localparam logic [27:0] REPEAT_TICKS = FAST_SIM ? 28'd2_343_750 : 28'd150_000_000;
    localparam logic [24:0] DUR_23 = FAST_SIM ? 25'd131_072 : 25'd8_388_608;
    localparam logic [24:0] DUR_22 = FAST_SIM ? 25'd65_536 : 25'd4_194_304;
    localparam logic [24:0] DUR_23_PLUS_22 = FAST_SIM ? 25'd196_608 : 25'd12_582_912;
    localparam logic [24:0] DUR_24 = FAST_SIM ? 25'd262_144 : 25'd16_777_216;
    // Full periods at 50 MHz. FAST_SIM makes every note 64 times faster.
    localparam logic [15:0] PERIOD_G6 = FAST_SIM ? 16'd498 : 16'd31_888;
    localparam logic [15:0] PERIOD_C7 = FAST_SIM ? 16'd373 : 16'd23_889;
    localparam logic [15:0] PERIOD_E7 = FAST_SIM ? 16'd296 : 16'd18_961;
    localparam logic [15:0] PERIOD_G7 = FAST_SIM ? 16'd249 : 16'd15_944;

    state_t cs, ns;
    logic [27:0] repeat_count;
    logic [24:0] note_count, note_duration;
    logic [15:0] tone_count, tone_period;
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
        else if (cs == WAIT || tone_count >= tone_period - 1'b1)
            tone_count <= '0;
        else
            tone_count <= tone_count + 1'b1;
    end

    always_comb begin
        ns = cs;
        note_duration = DUR_23;
        tone_period = PERIOD_G6;
        case (cs)
            WAIT: begin
                note_duration = DUR_23;
                tone_period = PERIOD_G6;
                if (too_fast)
                    ns = G6;
                else if (batt_low)
                    ns = G7_LONG;
                else if (en_steer && repeat_done)
                    ns = G6;
            end G6: begin
                note_duration = DUR_23;
                tone_period = PERIOD_G6;
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
                tone_period = PERIOD_C7;
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
                tone_period = PERIOD_E7;
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
                tone_period = PERIOD_G7;
                if (note_done) begin
                    if (too_fast)
                        ns = G6;
                    else if (batt_low)
                        ns = E7;
                    else
                        ns = E7_SHORT;
                end
            end E7_SHORT: begin
                note_duration = DUR_22;
                tone_period = PERIOD_E7;
                if (note_done) begin
                    if (too_fast)
                        ns = G6;
                    else if (batt_low)
                        ns = G7;
                    else
                        ns = G7_LONG;
                end
            end G7_LONG: begin
                note_duration = DUR_24;
                tone_period = PERIOD_G7;
                if (note_done) begin
                    if (too_fast)
                        ns = G6;
                    else if (batt_low)
                        ns = E7_SHORT;
                    else
                        ns = WAIT;
                end
            end default: begin
                ns = WAIT;
                note_duration = DUR_23;
                tone_period = PERIOD_G6;
            end
        endcase
    end

    assign piezo = (cs != WAIT) ? (tone_count < tone_period / 2) : 1'b0;
    assign piezo_n = (cs != WAIT) ? ~piezo : 1'b0;

endmodule
