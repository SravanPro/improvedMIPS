`timescale 1ns / 1ps
module movementDivider #(
    parameter SIM_MODE = 0 
)(
    input        clock,
    input        reset,
    input        rightRaw, leftRaw, upRaw, downRaw,
    input        speedInc, speedDec,
    output reg   right, left, up, down,
    output [3:0] speedOut
);
    localparam DIV_SCALE = (SIM_MODE) ? 100 : 1;
    localparam PULSE_WIDTH = 100;
    localparam DEBOUNCE_VAL = 1_000_000 / DIV_SCALE;

    reg [3:0] speed;
    assign speedOut = speed;

    // --- Debounce ---
    reg [19:0] db_inc_cnt, db_dec_cnt;
    reg db_inc_state, db_dec_state, prev_inc, prev_dec;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            {db_inc_cnt, db_dec_cnt, db_inc_state, db_dec_state, prev_inc, prev_dec} <= 0;
        end else begin
            prev_inc <= db_inc_state;
            prev_dec <= db_dec_state;
            if (speedInc == db_inc_state) db_inc_cnt <= 0;
            else if (db_inc_cnt >= DEBOUNCE_VAL) begin db_inc_state <= speedInc; db_inc_cnt <= 0; end
            else db_inc_cnt <= db_inc_cnt + 1;
            if (speedDec == db_dec_state) db_dec_cnt <= 0;
            else if (db_dec_cnt >= DEBOUNCE_VAL) begin db_dec_state <= speedDec; db_dec_cnt <= 0; end
            else db_dec_cnt <= db_dec_cnt + 1;
        end
    end

    // --- Divider Lookup (speed 15 = fastest = old speed 1) ---
    reg [23:0] divider;
    always @(*) begin
        case (speed)
            4'd15: divider = 666_666  / DIV_SCALE;
            4'd14: divider = 750_000  / DIV_SCALE;
            4'd13: divider = 833_333  / DIV_SCALE;
            4'd12: divider = 916_666  / DIV_SCALE;
            4'd11: divider = 1_000_000 / DIV_SCALE;
            4'd10: divider = 1_166_666 / DIV_SCALE;
            4'd9:  divider = 1_333_333 / DIV_SCALE;
            4'd8:  divider = 1_500_000 / DIV_SCALE;
            4'd7:  divider = 1_750_000 / DIV_SCALE;
            4'd6:  divider = 2_000_000 / DIV_SCALE;
            4'd5:  divider = 2_333_333 / DIV_SCALE;
            4'd4:  divider = 2_666_666 / DIV_SCALE;
            4'd3:  divider = 3_000_000 / DIV_SCALE;
            4'd2:  divider = 3_500_000 / DIV_SCALE;
            4'd1:  divider = 4_000_000 / DIV_SCALE;
            default: divider = 666_666  / DIV_SCALE;
        endcase
    end

    // --- Main Counter & Pulse Window ---
    reg [23:0] counter;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            speed <= 4'd15; counter <= 0;  // default to fastest
            {right, left, up, down} <= 4'b0;
        end else begin
            if (db_inc_state && !prev_inc && speed < 15) speed <= speed + 1;
            if (db_dec_state && !prev_dec && speed > 1)  speed <= speed - 1;
            if (counter >= divider - 1) counter <= 0;
            else counter <= counter + 1;
            if (counter < PULSE_WIDTH) begin
                {right, left, up, down} <= {rightRaw, leftRaw, upRaw, downRaw};
            end else begin
                {right, left, up, down} <= 4'b0;
            end
        end
    end
endmodule