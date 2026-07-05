`timescale 1ns / 1ps





module mem_wb (
    input  wire        clock,
    input  wire        reset,
    input  wire        mem_wb_stall,

    input  wire [31:0] mem_wb_NPC_in,
    input  wire [31:0] mem_wb_LMD_in,
    input  wire [31:0] mem_wb_AluOut_in,
    input  wire [4:0]  mem_wb_RD_in,


    input  wire        mem_wb_RegWrite_in,
    input  wire        mem_wb_MemToReg_in,
    input  wire        mem_wb_Jal_in,

    output reg  [31:0] mem_wb_NPC_out,
    output reg  [31:0] mem_wb_LMD_out,
    output reg  [31:0] mem_wb_AluOut_out,
    output reg  [4:0]  mem_wb_RD_out,


    output reg         mem_wb_RegWrite_out,
    output reg         mem_wb_MemToReg_out,
    output reg         mem_wb_Jal_out
);

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            mem_wb_NPC_out        <= 32'b0;
            mem_wb_LMD_out      <= 32'b0;
            mem_wb_AluOut_out   <= 32'b0;
            mem_wb_RD_out  <= 5'b0;
            mem_wb_RegWrite_out <= 1'b0;
            mem_wb_MemToReg_out <= 1'b0;
            mem_wb_Jal_out      <= 1'b0;
        end
        else if (mem_wb_stall) begin
            // hold everything, do not advance, used while fxpu is busy
            mem_wb_NPC_out        <= mem_wb_NPC_out;
            mem_wb_LMD_out      <= mem_wb_LMD_out;
            mem_wb_AluOut_out   <= mem_wb_AluOut_out;
            mem_wb_RD_out  <= mem_wb_RD_out;
            mem_wb_RegWrite_out <= mem_wb_RegWrite_out;
            mem_wb_MemToReg_out <= mem_wb_MemToReg_out;
            mem_wb_Jal_out      <= mem_wb_Jal_out;
        end
        else begin
            mem_wb_NPC_out        <= mem_wb_NPC_in;
            mem_wb_LMD_out      <= mem_wb_LMD_in;
            mem_wb_AluOut_out   <= mem_wb_AluOut_in;
            mem_wb_RD_out  <= mem_wb_RD_in;
            mem_wb_RegWrite_out <= mem_wb_RegWrite_in;
            mem_wb_MemToReg_out <= mem_wb_MemToReg_in;
            mem_wb_Jal_out      <= mem_wb_Jal_in;
        end
    end
endmodule