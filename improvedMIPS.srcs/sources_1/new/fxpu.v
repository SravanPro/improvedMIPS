`timescale 1ns / 1ps

module fxpu(
    input         clock,
    input         reset,
    input         start,     // pulse once to begin an op
    input         isDiv,     // 0 = multiply, 1 = divide
    input  [31:0] a,
    input  [31:0] b,
    input  [4:0]  f,         // fractional bits, latched at start
    output [31:0] result,
    output        busy,
    output        done
);

    // f is latched the cycle the op starts, so a switch flip mid op cant corrupt it
    reg [4:0] f_latched;
    reg       isDiv_latched;

    wire mul_busy, mul_done;
    wire div_busy, div_done;
    wire [63:0] mul_product;
    wire [31:0] div_quotient;

    // mul path: full 64 bit product, then scale down by f
    mul_booth_radix4 MUL (
        .clock(clock), .reset(reset),
        .start(start & ~isDiv),
        .a(a), .b(b),
        .product(mul_product),
        .busy(mul_busy), .done(mul_done)
    );

    // div path: dividend sign extended and shifted left by f before dividing
    wire [63:0] dividend_shifted = ($signed({{32{a[31]}}, a})) <<< f_latched;

    div_nonrestoring DIV (
        .clock(clock), .reset(reset),
        .start(start & isDiv),
        .dividend(dividend_shifted), .divisor(b),
        .quotient(div_quotient),
        .busy(div_busy), .done(div_done)
    );

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            f_latched     <= 5'b0;
            isDiv_latched <= 1'b0;
        end
        else if (start) begin
            f_latched     <= f;
            isDiv_latched <= isDiv;
        end
    end

    // mul result is scaled down by the latched f, arithmetic shift to keep the sign
    wire [63:0] mul_scaled = $signed(mul_product) >>> f_latched;

    assign result = isDiv_latched ? div_quotient : mul_scaled[31:0];
    assign busy   = mul_busy | div_busy;
    assign done   = mul_done | div_done;

endmodule