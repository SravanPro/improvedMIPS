`timescale 1ns / 1ps
// raycastRenderer - new implementation (scrapped old version per design doc §3.6)
//
// Consumes 128 integer column heights h0..h127 (each 32-bit, value 0-64).
// Renders a 64-row × 128-column framebuffer into the 8192-bit 'fb' output.
//
// Column c has height h = h<c>[6:0] (clamped 0-64).
//   top    = 32 - h/2   (row index, clamped to 0)
//   bottom = 32 + h/2   (row index, clamped to 63)
//   rows [top, bottom] in column c are set (wall), rest clear (floor/ceiling).
//
// Flat bit index convention matching spi.v's page_byte function:
//   fb[Y*128 + X]  where Y=row (0-63), X=col (0-127)
//
// Rendering is continuous: one column per clock cycle, looping forever.
// The 128-cycle latency is far inside the SPI frame budget.

module raycastRenderer (
    input  wire        clock,
    input  wire        reset,

    // 128 individual column heights from pipeline DMEM tap
    input  wire [31:0] h0,   input  wire [31:0] h1,   input  wire [31:0] h2,
    input  wire [31:0] h3,   input  wire [31:0] h4,   input  wire [31:0] h5,
    input  wire [31:0] h6,   input  wire [31:0] h7,   input  wire [31:0] h8,
    input  wire [31:0] h9,   input  wire [31:0] h10,  input  wire [31:0] h11,
    input  wire [31:0] h12,  input  wire [31:0] h13,  input  wire [31:0] h14,
    input  wire [31:0] h15,  input  wire [31:0] h16,  input  wire [31:0] h17,
    input  wire [31:0] h18,  input  wire [31:0] h19,  input  wire [31:0] h20,
    input  wire [31:0] h21,  input  wire [31:0] h22,  input  wire [31:0] h23,
    input  wire [31:0] h24,  input  wire [31:0] h25,  input  wire [31:0] h26,
    input  wire [31:0] h27,  input  wire [31:0] h28,  input  wire [31:0] h29,
    input  wire [31:0] h30,  input  wire [31:0] h31,  input  wire [31:0] h32,
    input  wire [31:0] h33,  input  wire [31:0] h34,  input  wire [31:0] h35,
    input  wire [31:0] h36,  input  wire [31:0] h37,  input  wire [31:0] h38,
    input  wire [31:0] h39,  input  wire [31:0] h40,  input  wire [31:0] h41,
    input  wire [31:0] h42,  input  wire [31:0] h43,  input  wire [31:0] h44,
    input  wire [31:0] h45,  input  wire [31:0] h46,  input  wire [31:0] h47,
    input  wire [31:0] h48,  input  wire [31:0] h49,  input  wire [31:0] h50,
    input  wire [31:0] h51,  input  wire [31:0] h52,  input  wire [31:0] h53,
    input  wire [31:0] h54,  input  wire [31:0] h55,  input  wire [31:0] h56,
    input  wire [31:0] h57,  input  wire [31:0] h58,  input  wire [31:0] h59,
    input  wire [31:0] h60,  input  wire [31:0] h61,  input  wire [31:0] h62,
    input  wire [31:0] h63,  input  wire [31:0] h64,  input  wire [31:0] h65,
    input  wire [31:0] h66,  input  wire [31:0] h67,  input  wire [31:0] h68,
    input  wire [31:0] h69,  input  wire [31:0] h70,  input  wire [31:0] h71,
    input  wire [31:0] h72,  input  wire [31:0] h73,  input  wire [31:0] h74,
    input  wire [31:0] h75,  input  wire [31:0] h76,  input  wire [31:0] h77,
    input  wire [31:0] h78,  input  wire [31:0] h79,  input  wire [31:0] h80,
    input  wire [31:0] h81,  input  wire [31:0] h82,  input  wire [31:0] h83,
    input  wire [31:0] h84,  input  wire [31:0] h85,  input  wire [31:0] h86,
    input  wire [31:0] h87,  input  wire [31:0] h88,  input  wire [31:0] h89,
    input  wire [31:0] h90,  input  wire [31:0] h91,  input  wire [31:0] h92,
    input  wire [31:0] h93,  input  wire [31:0] h94,  input  wire [31:0] h95,
    input  wire [31:0] h96,  input  wire [31:0] h97,  input  wire [31:0] h98,
    input  wire [31:0] h99,  input  wire [31:0] h100, input  wire [31:0] h101,
    input  wire [31:0] h102, input  wire [31:0] h103, input  wire [31:0] h104,
    input  wire [31:0] h105, input  wire [31:0] h106, input  wire [31:0] h107,
    input  wire [31:0] h108, input  wire [31:0] h109, input  wire [31:0] h110,
    input  wire [31:0] h111, input  wire [31:0] h112, input  wire [31:0] h113,
    input  wire [31:0] h114, input  wire [31:0] h115, input  wire [31:0] h116,
    input  wire [31:0] h117, input  wire [31:0] h118, input  wire [31:0] h119,
    input  wire [31:0] h120, input  wire [31:0] h121, input  wire [31:0] h122,
    input  wire [31:0] h123, input  wire [31:0] h124, input  wire [31:0] h125,
    input  wire [31:0] h126, input  wire [31:0] h127,

    output reg  [8191:0] fb
);

    // Pack h0..h127 into an addressable array for the sequencer
    wire [31:0] h_arr [0:127];
    assign h_arr[0]   = h0;   assign h_arr[1]   = h1;   assign h_arr[2]   = h2;
    assign h_arr[3]   = h3;   assign h_arr[4]   = h4;   assign h_arr[5]   = h5;
    assign h_arr[6]   = h6;   assign h_arr[7]   = h7;   assign h_arr[8]   = h8;
    assign h_arr[9]   = h9;   assign h_arr[10]  = h10;  assign h_arr[11]  = h11;
    assign h_arr[12]  = h12;  assign h_arr[13]  = h13;  assign h_arr[14]  = h14;
    assign h_arr[15]  = h15;  assign h_arr[16]  = h16;  assign h_arr[17]  = h17;
    assign h_arr[18]  = h18;  assign h_arr[19]  = h19;  assign h_arr[20]  = h20;
    assign h_arr[21]  = h21;  assign h_arr[22]  = h22;  assign h_arr[23]  = h23;
    assign h_arr[24]  = h24;  assign h_arr[25]  = h25;  assign h_arr[26]  = h26;
    assign h_arr[27]  = h27;  assign h_arr[28]  = h28;  assign h_arr[29]  = h29;
    assign h_arr[30]  = h30;  assign h_arr[31]  = h31;  assign h_arr[32]  = h32;
    assign h_arr[33]  = h33;  assign h_arr[34]  = h34;  assign h_arr[35]  = h35;
    assign h_arr[36]  = h36;  assign h_arr[37]  = h37;  assign h_arr[38]  = h38;
    assign h_arr[39]  = h39;  assign h_arr[40]  = h40;  assign h_arr[41]  = h41;
    assign h_arr[42]  = h42;  assign h_arr[43]  = h43;  assign h_arr[44]  = h44;
    assign h_arr[45]  = h45;  assign h_arr[46]  = h46;  assign h_arr[47]  = h47;
    assign h_arr[48]  = h48;  assign h_arr[49]  = h49;  assign h_arr[50]  = h50;
    assign h_arr[51]  = h51;  assign h_arr[52]  = h52;  assign h_arr[53]  = h53;
    assign h_arr[54]  = h54;  assign h_arr[55]  = h55;  assign h_arr[56]  = h56;
    assign h_arr[57]  = h57;  assign h_arr[58]  = h58;  assign h_arr[59]  = h59;
    assign h_arr[60]  = h60;  assign h_arr[61]  = h61;  assign h_arr[62]  = h62;
    assign h_arr[63]  = h63;  assign h_arr[64]  = h64;  assign h_arr[65]  = h65;
    assign h_arr[66]  = h66;  assign h_arr[67]  = h67;  assign h_arr[68]  = h68;
    assign h_arr[69]  = h69;  assign h_arr[70]  = h70;  assign h_arr[71]  = h71;
    assign h_arr[72]  = h72;  assign h_arr[73]  = h73;  assign h_arr[74]  = h74;
    assign h_arr[75]  = h75;  assign h_arr[76]  = h76;  assign h_arr[77]  = h77;
    assign h_arr[78]  = h78;  assign h_arr[79]  = h79;  assign h_arr[80]  = h80;
    assign h_arr[81]  = h81;  assign h_arr[82]  = h82;  assign h_arr[83]  = h83;
    assign h_arr[84]  = h84;  assign h_arr[85]  = h85;  assign h_arr[86]  = h86;
    assign h_arr[87]  = h87;  assign h_arr[88]  = h88;  assign h_arr[89]  = h89;
    assign h_arr[90]  = h90;  assign h_arr[91]  = h91;  assign h_arr[92]  = h92;
    assign h_arr[93]  = h93;  assign h_arr[94]  = h94;  assign h_arr[95]  = h95;
    assign h_arr[96]  = h96;  assign h_arr[97]  = h97;  assign h_arr[98]  = h98;
    assign h_arr[99]  = h99;  assign h_arr[100] = h100; assign h_arr[101] = h101;
    assign h_arr[102] = h102; assign h_arr[103] = h103; assign h_arr[104] = h104;
    assign h_arr[105] = h105; assign h_arr[106] = h106; assign h_arr[107] = h107;
    assign h_arr[108] = h108; assign h_arr[109] = h109; assign h_arr[110] = h110;
    assign h_arr[111] = h111; assign h_arr[112] = h112; assign h_arr[113] = h113;
    assign h_arr[114] = h114; assign h_arr[115] = h115; assign h_arr[116] = h116;
    assign h_arr[117] = h117; assign h_arr[118] = h118; assign h_arr[119] = h119;
    assign h_arr[120] = h120; assign h_arr[121] = h121; assign h_arr[122] = h122;
    assign h_arr[123] = h123; assign h_arr[124] = h124; assign h_arr[125] = h125;
    assign h_arr[126] = h126; assign h_arr[127] = h127;

    // Current column being rendered (0-127, advances each clock)
    reg [6:0] col;

    // Current column height (clamped 0-64)
    wire [31:0] h_word = h_arr[col];
    wire [6:0]  h      = (h_word[6:0] > 7'd64) ? 7'd64 : h_word[6:0];

    // top/bottom row for this column
    wire [6:0] half       = h >> 1;
    wire signed [7:0] top_s    = 8'sd32 - {1'b0, half};
    wire signed [7:0] bottom_s = 8'sd32 + {1'b0, half};
    wire [5:0] top    = (top_s    < 0)      ? 6'd0  : top_s[5:0];
    wire [5:0] bottom = (bottom_s > 8'sd63) ? 6'd63 : bottom_s[5:0];

    // Row-in-column mask (combinational, all 64 rows at once)
    reg [63:0] rowMask;
    integer r;
    always @(*) begin
        for (r = 0; r < 64; r = r + 1)
            rowMask[r] = (r[5:0] >= top) && (r[5:0] <= bottom);
    end

    // Write one column per clock; loop forever picking up fresh heights
    integer rr;
always @(posedge clock or posedge reset) begin
    if (reset) begin
        fb  <= 8192'b0;
        col <= 7'd0;
    end else begin
        for (rr = 0; rr < 64; rr = rr + 1)
            fb[{rr[5:0], 7'b0} | {7'b0, col}] <= rowMask[rr];
        col <= (col == 7'd127) ? 7'd0 : col + 7'd1;
    end
end

endmodule