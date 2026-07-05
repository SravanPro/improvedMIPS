`timescale 1ns / 1ps

module jrControl (
    input  [5:0] opcode,
    input  [5:0] funct,
    output       jr
);
    assign jr = (opcode == 6'b000000) && (funct == 6'b001000);
endmodule