`timescale 1ns / 1ps






module id_ex (
    input  wire        clock,
    input  wire        reset,
    input  wire        id_ex_stall,
    input  wire        id_ex_flush,



    input  wire [31:0] id_ex_NPC_in,
    input  wire [31:0] id_ex_A_in,
    input  wire [31:0] id_ex_B_in,
    input  wire [31:0] id_ex_Imm_in,
    input  wire [4:0]  id_ex_RS_in,
    input  wire [4:0]  id_ex_RT_in,
    input  wire [4:0]  id_ex_RD_in,


    input  wire        id_ex_RegDst_in,
    input  wire        id_ex_ALUSrc_in,
    input  wire [3:0]  id_ex_ALUOp_in,


    input  wire        id_ex_BranchEq_in,
    input  wire        id_ex_BranchNe_in,

    input  wire        id_ex_MemRead_in,
    input  wire        id_ex_MemWrite_in,


    input  wire        id_ex_RegWrite_in,
    input  wire        id_ex_MemToReg_in,
    input  wire        id_ex_Jal_in,
    input  wire        id_ex_IsMul_in,
    input  wire        id_ex_IsDiv_in,


    output reg  [31:0] id_ex_NPC_out,
    output reg  [31:0] id_ex_A_out,
    output reg  [31:0] id_ex_B_out,
    output reg  [31:0] id_ex_Imm_out,
    output reg  [4:0]  id_ex_RS_out,
    output reg  [4:0]  id_ex_RT_out,
    output reg  [4:0]  id_ex_RD_out,


    output reg         id_ex_RegDst_out,
    output reg         id_ex_ALUSrc_out,
    output reg  [3:0]  id_ex_ALUOp_out,


    output reg         id_ex_BranchEq_out,
    output reg         id_ex_BranchNe_out,
    output reg         id_ex_MemRead_out,
    output reg         id_ex_MemWrite_out,


    output reg         id_ex_RegWrite_out,
    output reg         id_ex_MemToReg_out,
    output reg         id_ex_Jal_out,
    output reg         id_ex_IsMul_out,
    output reg         id_ex_IsDiv_out
);

    always @(posedge clock or posedge reset) begin
        if (reset || id_ex_flush) begin

            id_ex_NPC_out      <= 32'b0;
            id_ex_A_out        <= 32'b0;
            id_ex_B_out        <= 32'b0;
            id_ex_Imm_out      <= 32'b0;
            id_ex_RS_out       <= 5'b0;
            id_ex_RT_out       <= 5'b0;
            id_ex_RD_out       <= 5'b0;
            id_ex_RegDst_out   <= 1'b0;
            id_ex_ALUSrc_out   <= 1'b0;
            id_ex_ALUOp_out    <= 4'b0;            
            id_ex_BranchEq_out   <= 1'b0;
            id_ex_BranchNe_out   <= 1'b0;
            id_ex_MemRead_out  <= 1'b0;
            id_ex_MemWrite_out <= 1'b0;
            id_ex_RegWrite_out <= 1'b0;
            id_ex_MemToReg_out <= 1'b0;
            id_ex_Jal_out      <= 1'b0;
            id_ex_IsMul_out    <= 1'b0;
            id_ex_IsDiv_out    <= 1'b0;
        end
        else if (id_ex_stall) begin
            // hold previous values on stall, do not zero/advance
            id_ex_NPC_out      <= id_ex_NPC_out;
            id_ex_A_out        <= id_ex_A_out;
            id_ex_B_out        <= id_ex_B_out;
            id_ex_Imm_out      <= id_ex_Imm_out;
            id_ex_RS_out       <= id_ex_RS_out;
            id_ex_RT_out       <= id_ex_RT_out;
            id_ex_RD_out       <= id_ex_RD_out;
            id_ex_RegDst_out   <= id_ex_RegDst_out;
            id_ex_ALUSrc_out   <= id_ex_ALUSrc_out;
            id_ex_ALUOp_out    <= id_ex_ALUOp_out;
            id_ex_BranchEq_out   <= id_ex_BranchEq_out;
            id_ex_BranchNe_out   <= id_ex_BranchNe_out;
            id_ex_MemRead_out  <= id_ex_MemRead_out;
            id_ex_MemWrite_out <= id_ex_MemWrite_out;
            id_ex_RegWrite_out <= id_ex_RegWrite_out;
            id_ex_MemToReg_out <= id_ex_MemToReg_out;
            id_ex_Jal_out      <= id_ex_Jal_out;
            id_ex_IsMul_out    <= id_ex_IsMul_out;
            id_ex_IsDiv_out    <= id_ex_IsDiv_out;
        end
        else begin
            id_ex_NPC_out      <= id_ex_NPC_in;
            id_ex_A_out        <= id_ex_A_in;
            id_ex_B_out        <= id_ex_B_in;
            id_ex_Imm_out      <= id_ex_Imm_in;
            id_ex_RS_out       <= id_ex_RS_in;
            id_ex_RT_out       <= id_ex_RT_in;
            id_ex_RD_out       <= id_ex_RD_in;
            id_ex_RegDst_out   <= id_ex_RegDst_in;
            id_ex_ALUSrc_out   <= id_ex_ALUSrc_in;
            id_ex_ALUOp_out    <= id_ex_ALUOp_in;
            id_ex_BranchEq_out   <= id_ex_BranchEq_in;
            id_ex_BranchNe_out   <= id_ex_BranchNe_in;
            id_ex_MemRead_out  <= id_ex_MemRead_in;
            id_ex_MemWrite_out <= id_ex_MemWrite_in;
            id_ex_RegWrite_out <= id_ex_RegWrite_in;
            id_ex_MemToReg_out <= id_ex_MemToReg_in;
            id_ex_Jal_out      <= id_ex_Jal_in;
            id_ex_IsMul_out    <= id_ex_IsMul_in;
            id_ex_IsDiv_out    <= id_ex_IsDiv_in;
        end
    end
endmodule