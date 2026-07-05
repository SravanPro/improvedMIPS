`timescale 1ns / 1ps

module mainControl(
    input      [5:0] opCode,

    output reg       regDst,
    output reg       aluSrc,
    output reg       memToReg,
    output reg       regWrite,
    output reg       memRead,
    output reg       memWrite,
    output reg       branchEq,
    output reg       branchNe,
    output reg       jump,
    output reg       jal,
    output reg [3:0] aluOp
);

    always @(*) begin

        regDst   = 1'b0;
        aluSrc   = 1'b0;
        memToReg = 1'b0;
        regWrite = 1'b0;
        memRead  = 1'b0;
        memWrite = 1'b0;
        
        branchEq   = 1'b0;
        branchNe   = 1'b0;
        
        jump     = 1'b0;
        jal      = 1'b0;
        aluOp    = 4'b0000;

        case (opCode)
            6'b000000: begin
                regDst   = 1'b1;
                regWrite = 1'b1;
                aluOp    = 4'b0010;
            end



            //lw
            6'b100011: begin
                aluSrc   = 1'b1;
                memToReg = 1'b1;
                regWrite = 1'b1;
                memRead  = 1'b1;
                aluOp    = 4'b0000;
            end

            //sw
            6'b101011: begin
                aluSrc   = 1'b1;
                memWrite = 1'b1;
                aluOp    = 4'b0000;
            end
             
            //beq
            6'b000100: begin
                branchEq = 1'b1;
                aluOp    = 4'b0001;
            end
            //bne
            6'b000101: begin
                branchNe = 1'b1;
                aluOp    = 4'b0001;
            end



            //addi
            6'b001000: begin
                aluSrc   = 1'b1;
                regWrite = 1'b1;
                aluOp    = 4'b0000;
            end     

            //andi
            6'b001100: begin
                aluSrc   = 1'b1;
                regWrite = 1'b1;
                aluOp    = 4'b0011;
            end  

            //ori
            6'b001101: begin
                aluSrc   = 1'b1;
                regWrite = 1'b1;
                aluOp    = 4'b0100;
            end    

            //xori
            6'b001110: begin
                aluSrc   = 1'b1;
                regWrite = 1'b1;
                aluOp    = 4'b0101;
            end   
            
            //slti
            6'b001010: begin
                aluSrc   = 1'b1;
                regWrite = 1'b1;
                aluOp    = 4'b0110;
            end

            //lui
            6'b001111: begin
                aluSrc   = 1'b1;
                regWrite = 1'b1;
                aluOp    = 4'b0111;
            end

            //j
            6'b000010: begin
                jump     = 1'b1;
            end

            //jal
            6'b000011: begin
                jal      = 1'b1;
                regWrite = 1'b1;
            end


            default: begin

            end
        endcase
    end
endmodule
