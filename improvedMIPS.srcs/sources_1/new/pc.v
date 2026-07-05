`timescale 1ns / 1ps

module pc(
    input        clock,
    input        reset,
    input        pcStall,
    input [31:0] pcInVal,
    output reg [31:0] pcOutVal
);

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            pcOutVal <= 32'd0;
        end
        else if (pcStall) begin
            pcOutVal <= pcOutVal;
        end
        else begin
            pcOutVal <= pcInVal;
        end
    end

endmodule
