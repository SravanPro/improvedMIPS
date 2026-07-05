`timescale 1ns / 1ps

module adder #(parameter width = 32)(
    input  [width-1:0] a,
    input  [width-1:0] b,
    output [width-1:0] sum
);

    assign sum = a + b;

endmodule
