`timescale 1ns / 1ps


module aluControl(
    input  [3:0] aluOp,
    input  [5:0] func,
    output reg [3:0] op
);

    always @(*) begin
        case (aluOp)
            4'b0000: op = 4'b0010;
            4'b0001: op = 4'b0110;
             
            //andi
            4'b0011: op = 4'b0000; 
            //ori
            4'b0100: op = 4'b0001;
            //xori
            4'b0101: op = 4'b1001;
            //slti:
            4'b0110: op = 4'b0111;
            //lui
            4'b0111: op = 4'b0101;

            4'b0010: begin
                case (func)
                    6'b100000: op = 4'b0010;
                    6'b100010: op = 4'b0110;
                    6'b100100: op = 4'b0000;
                    6'b100101: op = 4'b0001;
                    6'b101010: op = 4'b0111;
                    6'b100111: op = 4'b1000;
                    6'b100110: op = 4'b1001;
                    6'b000000:  op = 4'b1010;
                    6'b000010:  op = 4'b1011;
                    6'b000011:  op = 4'b1100;
                    6'b101100:  op = 4'b0100;
                    6'b001000:  op = 4'b0100; // jr
                    6'b000100: op = 4'b1010; // sllv
                    6'b000110: op = 4'b1011; // srlv
                    6'b000111: op = 4'b1100; // srav
                    default: op = 4'b0010;
                endcase
            end

            default: op = 4'b0010;
        endcase
    end
endmodule
