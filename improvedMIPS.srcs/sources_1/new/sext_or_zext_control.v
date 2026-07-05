`timescale 1ns / 1ps

module sext_or_zext_control(
    input [3:0] aluOp,
    output reg sext_or_zext
);

    always @(*) begin
        case (aluOp)
            4'b0011: sext_or_zext = 1'b1;
            4'b0100: sext_or_zext = 1'b1;
            4'b0101: sext_or_zext = 1'b1;
            4'b0111: sext_or_zext = 1'b1;
            default: sext_or_zext = 1'b0;
        endcase
    end
endmodule

