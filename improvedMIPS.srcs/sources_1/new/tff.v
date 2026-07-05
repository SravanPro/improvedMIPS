`timescale 1ns / 1ps


module tff(
    input clock, reset, t,
    output reg q
);

    initial q = 1'b0;  // ← add this line

    always @(posedge clock or posedge reset) begin
        if(reset) q <= 0;
        else begin
            if(t) q <= ~q;
            else q <= q;
        end
    end
endmodule
