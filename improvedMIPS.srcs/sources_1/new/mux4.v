`timescale 1ns / 1ps

module mux4 #(parameter width = 32)(

    input  [width-1:0] in0,
    input  [width-1:0] in1,
    input  [width-1:0] in2,
    input  [width-1:0] in3,
    input  [1:0] s,
    output [width-1:0] out
);

    assign out = (s == 2'b00) ? in0 :
                         (s == 2'b01) ? in1 :
                         (s == 2'b10) ? in2 :  
                                               in3;

endmodule
