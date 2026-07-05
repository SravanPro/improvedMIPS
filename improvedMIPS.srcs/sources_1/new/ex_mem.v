`timescale 1ns / 1ps






module ex_mem (
    input  wire        clock,
    input  wire        reset,
    input  wire        ex_mem_flush,
    input  wire        ex_mem_stall,


    input  wire [31:0] ex_mem_NPC_in,
    input  wire [31:0] ex_mem_BranchTarget_in,
    input  wire        ex_mem_Zero_in,
    input  wire [31:0] ex_mem_AluOut_in,
    input  wire [31:0] ex_mem_B_in,
    input  wire [4:0]  ex_mem_RD_in,


    input  wire        ex_mem_BranchEq_in,
    input  wire        ex_mem_BranchNe_in,
    input  wire        ex_mem_MemRead_in,
    input  wire        ex_mem_MemWrite_in,


    input  wire        ex_mem_RegWrite_in,
    input  wire        ex_mem_MemToReg_in,
    input  wire        ex_mem_Jal_in,


    output reg  [31:0] ex_mem_NPC_out,
    output reg  [31:0] ex_mem_BranchTarget_out,
    output reg         ex_mem_Zero_out,
    output reg  [31:0] ex_mem_AluOut_out,
    output reg  [31:0] ex_mem_B_out,
    output reg  [4:0]  ex_mem_RD_out,


    output reg         ex_mem_BranchEq_out,
    output reg         ex_mem_BranchNe_out,
    output reg         ex_mem_MemRead_out,
    output reg         ex_mem_MemWrite_out,


    output reg         ex_mem_RegWrite_out,
    output reg         ex_mem_MemToReg_out,
    output reg         ex_mem_Jal_out
);

    always @(posedge clock or posedge reset) begin
        if (reset || ex_mem_flush) begin

            ex_mem_NPC_out        <= 32'b0;
            ex_mem_BranchTarget_out <= 32'b0;
            ex_mem_Zero_out         <= 1'b0;
            ex_mem_AluOut_out       <= 32'b0;
            ex_mem_B_out            <= 32'b0;
            ex_mem_RD_out      <= 5'b0;

            ex_mem_BranchEq_out       <= 1'b0;
            ex_mem_BranchNe_out       <= 1'b0;
            ex_mem_MemRead_out      <= 1'b0;
            ex_mem_MemWrite_out     <= 1'b0;

            ex_mem_RegWrite_out     <= 1'b0;
            ex_mem_MemToReg_out     <= 1'b0;
            ex_mem_Jal_out        <= 1'b0;
        end
        else if (ex_mem_stall) begin
            // hold everything, do not advance, used while fxpu is busy
            ex_mem_NPC_out        <= ex_mem_NPC_out;
            ex_mem_BranchTarget_out <= ex_mem_BranchTarget_out;
            ex_mem_Zero_out         <= ex_mem_Zero_out;
            ex_mem_AluOut_out       <= ex_mem_AluOut_out;
            ex_mem_B_out            <= ex_mem_B_out;
            ex_mem_RD_out      <= ex_mem_RD_out;

            ex_mem_BranchEq_out       <= ex_mem_BranchEq_out;
            ex_mem_BranchNe_out       <= ex_mem_BranchNe_out;
            ex_mem_MemRead_out      <= ex_mem_MemRead_out;
            ex_mem_MemWrite_out     <= ex_mem_MemWrite_out;

            ex_mem_RegWrite_out     <= ex_mem_RegWrite_out;
            ex_mem_MemToReg_out     <= ex_mem_MemToReg_out;
            ex_mem_Jal_out        <= ex_mem_Jal_out;
        end
        else begin
            ex_mem_NPC_out        <= ex_mem_NPC_in;
            ex_mem_BranchTarget_out <= ex_mem_BranchTarget_in;
            ex_mem_Zero_out         <= ex_mem_Zero_in;
            ex_mem_AluOut_out       <= ex_mem_AluOut_in;
            ex_mem_B_out            <= ex_mem_B_in;
            ex_mem_RD_out      <= ex_mem_RD_in;

            ex_mem_BranchEq_out       <= ex_mem_BranchEq_in;
            ex_mem_BranchNe_out       <= ex_mem_BranchNe_in;
            ex_mem_MemRead_out      <= ex_mem_MemRead_in;
            ex_mem_MemWrite_out     <= ex_mem_MemWrite_in;

            ex_mem_RegWrite_out     <= ex_mem_RegWrite_in;
            ex_mem_MemToReg_out     <= ex_mem_MemToReg_in;
            ex_mem_Jal_out        <= ex_mem_Jal_in;
        end
    end
endmodule