`timescale 1ns / 1ps

module jTypeAddressProcessor(
    input [31:0] if_id_IR,
    input [31:0] if_id_NPC,
    output [31:0] jumpAddress

);

    assign jumpAddress = {if_id_NPC[31:28], if_id_IR[25:0], 2'b00};
endmodule
