`timescale 1ns / 1ps

module hazardDetectionUnit (
    input        id_ex_MemRead,
    input  [4:0] id_ex_RT,
    input  [4:0] if_id_RS,
    input  [4:0] if_id_RT,
    output reg   PCWrite,
    output reg   IF_IDWrite,
    output reg   ID_EXStall
);
    always @(*) begin
        PCWrite    = 1'b1;
        IF_IDWrite = 1'b1;
        ID_EXStall = 1'b0;

        if (id_ex_MemRead &&
            ((id_ex_RT == if_id_RS) || (id_ex_RT == if_id_RT))
        ) begin
            PCWrite    = 1'b0;
            IF_IDWrite = 1'b0;
            ID_EXStall = 1'b1;
        end
    end
endmodule