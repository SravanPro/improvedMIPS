`timescale 1ns / 1ps

module div_nonrestoring(
    input         clock,
    input         reset,
    input         start,
    input  [63:0] dividend,   // already shifted by f, sign extended by caller
    input  [31:0] divisor,
    output [31:0] quotient,
    output        busy,
    output        done
);

    // a is the remainder register, one extra bit wide to hold its own sign
    // q holds the working dividend bits, its msb is shifted into a each cycle
    // on each step: if a is non negative, a = (a<<1 | next q bit) - divisor
    //               if a is negative,     a = (a<<1 | next q bit) + divisor
    // the new quotient bit is 1 if the new a is non negative, else 0
    // no separate final correction needed, each step already self corrects

    reg signed [32:0] a;
    reg        [31:0] q;
    reg        [31:0] divisor_r;
    reg                neg_result;
    reg                dividend_was_zero;
    reg        [4:0]   count;
    reg                busy_r;
    reg                done_r;

    wire signed [32:0] a_shift_in = {a[31:0], q[31]};
    wire signed [32:0] a_minus_d  = a_shift_in - $signed({1'b0, divisor_r});
    wire signed [32:0] a_plus_d   = a_shift_in + $signed({1'b0, divisor_r});
    wire signed [32:0] a_next     = a[32] ? a_plus_d : a_minus_d;

    reg [63:0] abs_dividend;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            a          <= 33'b0;
            q          <= 32'b0;
            divisor_r  <= 32'b0;
            neg_result <= 1'b0;
            dividend_was_zero <= 1'b0;
            count      <= 5'b0;
            busy_r     <= 1'b0;
            done_r     <= 1'b0;
        end
        else begin
            done_r <= 1'b0;

            if (start && !busy_r) begin
                // take absolute value of the 64 bit dividend
                // high 32 bits seed the remainder, low 32 bits are the working q register
                abs_dividend = dividend[63] ? (~dividend + 64'd1) : dividend;
                a    <= {1'b0, abs_dividend[63:32]};
                q    <= abs_dividend[31:0];
                divisor_r  <= divisor[31] ? (~divisor + 32'd1) : divisor;
                neg_result <= dividend[63] ^ divisor[31];
                dividend_was_zero <= (dividend == 64'b0);
                count  <= 5'd0;
                busy_r <= 1'b1;
            end
            else if (busy_r) begin
                a <= a_next;
                q <= {q[30:0], ~a_next[32]};   // new quotient bit = 1 if a_next is non negative
                count <= count + 5'd1;

                if (count == 5'd31) begin
                    busy_r <= 1'b0;
                    done_r <= 1'b1;
                end
            end
        end
    end

    // divisor of zero is a special case, output all 1s
    // otherwise apply the sign we recorded at the start
    assign quotient = (divisor_r == 32'b0) ? 32'hFFFFFFFF :
                       dividend_was_zero    ? 32'b0 :
                       neg_result ? (~q + 32'd1) : q;

    assign busy = busy_r;
    assign done = done_r;

endmodule