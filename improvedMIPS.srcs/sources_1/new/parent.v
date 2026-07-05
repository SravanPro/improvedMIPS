`timescale 1ns / 1ps

module parent #(parameter inputs = 256, parameter SIM_MODE = 0)(
    input clock,
    input reset,
    input white, black, brown, red, gameRst, erase, draw,
    input speedInc, speedDec,
    input sw,
    output sck,
    output sda,
    output res,
    output dc,
    output cs,
    output [3:0] speedOut,
    output [6:0] seg0,
    output [6:0] seg1,
    output half_digit
);

    tff TFF (
        .clock(clock),
        .reset(reset),
        .t(1'b1),
        .q(t_ff_clk)
    );

    wire rightRaw, leftRaw, upRaw, downRaw;
    analogTranslator ANALOG_TRANSLATOR (
        .white(white), .black(black), .brown(brown), .red(red),
        .right(rightRaw), .left(leftRaw), .up(upRaw), .down(downRaw)
    );

    wire right, left, up, down;
    movementDivider #(.SIM_MODE(SIM_MODE)) MOVEMENT_DIVIDER (
        .clock(t_ff_clk), .reset(reset),
        .rightRaw(rightRaw), .leftRaw(leftRaw), .upRaw(upRaw), .downRaw(downRaw),
        .speedInc(speedInc), .speedDec(speedDec),
        .right(right), .left(left), .up(up), .down(down),
        .speedOut(speedOut)
    );

    wire [31:0] r1, r2;
    wire [inputs-1:0] memMappedIO = {{(inputs-7){1'b0}}, gameRst, erase, draw, down, up, left, right};

    // h0..h127: individual 32-bit column heights from pipeline DMEM tap
    wire [31:0] h0,  h1,  h2,  h3,  h4,  h5,  h6,  h7,
                h8,  h9,  h10, h11, h12, h13, h14, h15,
                h16, h17, h18, h19, h20, h21, h22, h23,
                h24, h25, h26, h27, h28, h29, h30, h31,
                h32, h33, h34, h35, h36, h37, h38, h39,
                h40, h41, h42, h43, h44, h45, h46, h47,
                h48, h49, h50, h51, h52, h53, h54, h55,
                h56, h57, h58, h59, h60, h61, h62, h63,
                h64, h65, h66, h67, h68, h69, h70, h71,
                h72, h73, h74, h75, h76, h77, h78, h79,
                h80, h81, h82, h83, h84, h85, h86, h87,
                h88, h89, h90, h91, h92, h93, h94, h95,
                h96, h97, h98, h99, h100,h101,h102,h103,
                h104,h105,h106,h107,h108,h109,h110,h111,
                h112,h113,h114,h115,h116,h117,h118,h119,
                h120,h121,h122,h123,h124,h125,h126,h127;

    pipeline #(.inputs(inputs)) PIPELINE (
        .clock(t_ff_clk), .reset(reset),
        .memMappedIO(memMappedIO),
        .r1(r1), .r2(r2),
        .h0(h0),   .h1(h1),   .h2(h2),   .h3(h3),   .h4(h4),   .h5(h5),   .h6(h6),   .h7(h7),
        .h8(h8),   .h9(h9),   .h10(h10), .h11(h11), .h12(h12), .h13(h13), .h14(h14), .h15(h15),
        .h16(h16), .h17(h17), .h18(h18), .h19(h19), .h20(h20), .h21(h21), .h22(h22), .h23(h23),
        .h24(h24), .h25(h25), .h26(h26), .h27(h27), .h28(h28), .h29(h29), .h30(h30), .h31(h31),
        .h32(h32), .h33(h33), .h34(h34), .h35(h35), .h36(h36), .h37(h37), .h38(h38), .h39(h39),
        .h40(h40), .h41(h41), .h42(h42), .h43(h43), .h44(h44), .h45(h45), .h46(h46), .h47(h47),
        .h48(h48), .h49(h49), .h50(h50), .h51(h51), .h52(h52), .h53(h53), .h54(h54), .h55(h55),
        .h56(h56), .h57(h57), .h58(h58), .h59(h59), .h60(h60), .h61(h61), .h62(h62), .h63(h63),
        .h64(h64), .h65(h65), .h66(h66), .h67(h67), .h68(h68), .h69(h69), .h70(h70), .h71(h71),
        .h72(h72), .h73(h73), .h74(h74), .h75(h75), .h76(h76), .h77(h77), .h78(h78), .h79(h79),
        .h80(h80), .h81(h81), .h82(h82), .h83(h83), .h84(h84), .h85(h85), .h86(h86), .h87(h87),
        .h88(h88), .h89(h89), .h90(h90), .h91(h91), .h92(h92), .h93(h93), .h94(h94), .h95(h95),
        .h96(h96), .h97(h97), .h98(h98), .h99(h99), .h100(h100),.h101(h101),.h102(h102),.h103(h103),
        .h104(h104),.h105(h105),.h106(h106),.h107(h107),.h108(h108),.h109(h109),.h110(h110),.h111(h111),
        .h112(h112),.h113(h113),.h114(h114),.h115(h115),.h116(h116),.h117(h117),.h118(h118),.h119(h119),
        .h120(h120),.h121(h121),.h122(h122),.h123(h123),.h124(h124),.h125(h125),.h126(h126),.h127(h127)
    );

    segmentDisplayDecoder SEGMENT_DISPLAY_DECODER (
        .sw(sw),
        .X(r1[6:0]), .Y(r2[5:0]),
        .seg0(seg0), .seg1(seg1), .half_digit(half_digit)
    );

    wire [8191:0] framebufferNet;
    raycastRenderer RAYCAST_RENDERER (
        .clock(t_ff_clk), .reset(reset),
        .h0(h0),   .h1(h1),   .h2(h2),   .h3(h3),   .h4(h4),   .h5(h5),   .h6(h6),   .h7(h7),
        .h8(h8),   .h9(h9),   .h10(h10), .h11(h11), .h12(h12), .h13(h13), .h14(h14), .h15(h15),
        .h16(h16), .h17(h17), .h18(h18), .h19(h19), .h20(h20), .h21(h21), .h22(h22), .h23(h23),
        .h24(h24), .h25(h25), .h26(h26), .h27(h27), .h28(h28), .h29(h29), .h30(h30), .h31(h31),
        .h32(h32), .h33(h33), .h34(h34), .h35(h35), .h36(h36), .h37(h37), .h38(h38), .h39(h39),
        .h40(h40), .h41(h41), .h42(h42), .h43(h43), .h44(h44), .h45(h45), .h46(h46), .h47(h47),
        .h48(h48), .h49(h49), .h50(h50), .h51(h51), .h52(h52), .h53(h53), .h54(h54), .h55(h55),
        .h56(h56), .h57(h57), .h58(h58), .h59(h59), .h60(h60), .h61(h61), .h62(h62), .h63(h63),
        .h64(h64), .h65(h65), .h66(h66), .h67(h67), .h68(h68), .h69(h69), .h70(h70), .h71(h71),
        .h72(h72), .h73(h73), .h74(h74), .h75(h75), .h76(h76), .h77(h77), .h78(h78), .h79(h79),
        .h80(h80), .h81(h81), .h82(h82), .h83(h83), .h84(h84), .h85(h85), .h86(h86), .h87(h87),
        .h88(h88), .h89(h89), .h90(h90), .h91(h91), .h92(h92), .h93(h93), .h94(h94), .h95(h95),
        .h96(h96), .h97(h97), .h98(h98), .h99(h99), .h100(h100),.h101(h101),.h102(h102),.h103(h103),
        .h104(h104),.h105(h105),.h106(h106),.h107(h107),.h108(h108),.h109(h109),.h110(h110),.h111(h111),
        .h112(h112),.h113(h113),.h114(h114),.h115(h115),.h116(h116),.h117(h117),.h118(h118),.h119(h119),
        .h120(h120),.h121(h121),.h122(h122),.h123(h123),.h124(h124),.h125(h125),.h126(h126),.h127(h127),
        .fb(framebufferNet)
    );

    spi SPI (
        .clock(t_ff_clk), .reset(reset),
        .fb(framebufferNet),
        .sck(sck), .sda(sda), .res(res), .dc(dc), .cs(cs)
    );

endmodule