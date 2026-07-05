`timescale 1ns / 1ps

module if_id (
    input  wire        clock,
    input  wire        reset,
    input  wire        if_id_stall,
    input  wire        if_id_flush,
    input  wire [31:0] if_id_NPC_in,
    input  wire [31:0] if_id_IR_in,

    output reg  [31:0] if_id_NPC_out,
    output reg  [31:0] if_id_IR_out
);
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            if_id_NPC_out <= 32'b0;
            if_id_IR_out  <= 32'b0;
        end
        else if (if_id_flush) begin
            if_id_NPC_out <= 32'b0;
            if_id_IR_out  <= 32'b0;
        end
        else if (if_id_stall) begin
            if_id_NPC_out <= if_id_NPC_out;
            if_id_IR_out  <= if_id_IR_out;
        end
        else begin
            if_id_NPC_out <= if_id_NPC_in;
            if_id_IR_out  <= if_id_IR_in;
        end
    end
endmodule

