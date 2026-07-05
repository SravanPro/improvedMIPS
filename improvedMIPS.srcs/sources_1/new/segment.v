
module segmentDisplayDecoder (
    input  wire       sw,         // 0 → display X, 1 → display Y
    input  wire [6:0] X,          // 7-bit input, 0-127
    input  wire [5:0] Y,          // 6-bit input, 0-63
    output reg  [6:0] seg0,       // digit index 0  {G,F,E,D,C,B,A}
    output reg  [6:0] seg1,       // digit index 1  {G,F,E,D,C,B,A}
    output wire       half_digit  // digit index 2: high when sw==0 & X>=100
);

    assign half_digit = (!sw) && (X >= 7'd100);

    reg [3:0] ones, tens;

    always @(*) begin
        if (sw) begin
            tens = Y / 4'd10;
            ones = Y % 4'd10;
        end else begin
            tens = (X % 7'd100) / 4'd10;
            ones = X % 4'd10;
        end
    end


    function [6:0] bcd_to_seg;
        input [3:0] bcd;
        case (bcd)
            4'd0:    bcd_to_seg = 7'h3F;
            4'd1:    bcd_to_seg = 7'h06;
            4'd2:    bcd_to_seg = 7'h5B;
            4'd3:    bcd_to_seg = 7'h4F;
            4'd4:    bcd_to_seg = 7'h66;
            4'd5:    bcd_to_seg = 7'h6D;
            4'd6:    bcd_to_seg = 7'h7D;
            4'd7:    bcd_to_seg = 7'h07;
            4'd8:    bcd_to_seg = 7'h7F;
            4'd9:    bcd_to_seg = 7'h6F;
            default: bcd_to_seg = 7'h00; // blank
        endcase
    endfunction

    always @(*) begin
        seg0 = bcd_to_seg(ones);
        seg1 = bcd_to_seg(tens);
    end

endmodule