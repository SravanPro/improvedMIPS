`timescale 1ns / 1ps

// memorySizeInBytes increased to 3000 to accommodate:
//   1444 B  Sine LUT
//    400 B  Arena map (word-packed, 100*4)
//    512 B  Ray lengths (128*4, FP 24.8)
//    512 B  Column heights (128*4, integer)
//     16 B  DDA scratch (4 words)
//    116 B  padding
// = 3000 B total

module memory #(parameter memorySizeInBytes = 3000, parameter ioWidth = 256)
(
    input  wire        clock, reset,
    input  wire        memWrite, memRead,
    input  wire [31:0] address,
    input  wire [31:0] writeData,
    input  wire [ioWidth-1:0] memMappedIO,
    output reg  [31:0] readData
);

    integer i;
    reg [7:0] mem [memorySizeInBytes-1:0];

    initial begin
        for (i = 0; i < memorySizeInBytes; i = i + 1) mem[i] = 8'h00;

        // ---- Sine LUT: angles 0..360 (FP 24.8, big-endian) ----
        mem[0] = 8'h00; mem[1] = 8'h00; mem[2] = 8'h00; mem[3] = 8'h00;
        mem[4] = 8'h00; mem[5] = 8'h00; mem[6] = 8'h00; mem[7] = 8'h04;
        mem[8] = 8'h00; mem[9] = 8'h00; mem[10] = 8'h00; mem[11] = 8'h09;
        mem[12] = 8'h00; mem[13] = 8'h00; mem[14] = 8'h00; mem[15] = 8'h0D;
        mem[16] = 8'h00; mem[17] = 8'h00; mem[18] = 8'h00; mem[19] = 8'h12;
        mem[20] = 8'h00; mem[21] = 8'h00; mem[22] = 8'h00; mem[23] = 8'h16;
        mem[24] = 8'h00; mem[25] = 8'h00; mem[26] = 8'h00; mem[27] = 8'h1B;
        mem[28] = 8'h00; mem[29] = 8'h00; mem[30] = 8'h00; mem[31] = 8'h1F;
        mem[32] = 8'h00; mem[33] = 8'h00; mem[34] = 8'h00; mem[35] = 8'h24;
        mem[36] = 8'h00; mem[37] = 8'h00; mem[38] = 8'h00; mem[39] = 8'h28;
        mem[40] = 8'h00; mem[41] = 8'h00; mem[42] = 8'h00; mem[43] = 8'h2C;
        mem[44] = 8'h00; mem[45] = 8'h00; mem[46] = 8'h00; mem[47] = 8'h31;
        mem[48] = 8'h00; mem[49] = 8'h00; mem[50] = 8'h00; mem[51] = 8'h35;
        mem[52] = 8'h00; mem[53] = 8'h00; mem[54] = 8'h00; mem[55] = 8'h3A;
        mem[56] = 8'h00; mem[57] = 8'h00; mem[58] = 8'h00; mem[59] = 8'h3E;
        mem[60] = 8'h00; mem[61] = 8'h00; mem[62] = 8'h00; mem[63] = 8'h42;
        mem[64] = 8'h00; mem[65] = 8'h00; mem[66] = 8'h00; mem[67] = 8'h47;
        mem[68] = 8'h00; mem[69] = 8'h00; mem[70] = 8'h00; mem[71] = 8'h4B;
        mem[72] = 8'h00; mem[73] = 8'h00; mem[74] = 8'h00; mem[75] = 8'h4F;
        mem[76] = 8'h00; mem[77] = 8'h00; mem[78] = 8'h00; mem[79] = 8'h53;
        mem[80] = 8'h00; mem[81] = 8'h00; mem[82] = 8'h00; mem[83] = 8'h58;
        mem[84] = 8'h00; mem[85] = 8'h00; mem[86] = 8'h00; mem[87] = 8'h5C;
        mem[88] = 8'h00; mem[89] = 8'h00; mem[90] = 8'h00; mem[91] = 8'h60;
        mem[92] = 8'h00; mem[93] = 8'h00; mem[94] = 8'h00; mem[95] = 8'h64;
        mem[96] = 8'h00; mem[97] = 8'h00; mem[98] = 8'h00; mem[99] = 8'h68;
        mem[100] = 8'h00; mem[101] = 8'h00; mem[102] = 8'h00; mem[103] = 8'h6C;
        mem[104] = 8'h00; mem[105] = 8'h00; mem[106] = 8'h00; mem[107] = 8'h70;
        mem[108] = 8'h00; mem[109] = 8'h00; mem[110] = 8'h00; mem[111] = 8'h74;
        mem[112] = 8'h00; mem[113] = 8'h00; mem[114] = 8'h00; mem[115] = 8'h78;
        mem[116] = 8'h00; mem[117] = 8'h00; mem[118] = 8'h00; mem[119] = 8'h7C;
        mem[120] = 8'h00; mem[121] = 8'h00; mem[122] = 8'h00; mem[123] = 8'h80;
        mem[124] = 8'h00; mem[125] = 8'h00; mem[126] = 8'h00; mem[127] = 8'h84;
        mem[128] = 8'h00; mem[129] = 8'h00; mem[130] = 8'h00; mem[131] = 8'h88;
        mem[132] = 8'h00; mem[133] = 8'h00; mem[134] = 8'h00; mem[135] = 8'h8B;
        mem[136] = 8'h00; mem[137] = 8'h00; mem[138] = 8'h00; mem[139] = 8'h8F;
        mem[140] = 8'h00; mem[141] = 8'h00; mem[142] = 8'h00; mem[143] = 8'h93;
        mem[144] = 8'h00; mem[145] = 8'h00; mem[146] = 8'h00; mem[147] = 8'h96;
        mem[148] = 8'h00; mem[149] = 8'h00; mem[150] = 8'h00; mem[151] = 8'h9A;
        mem[152] = 8'h00; mem[153] = 8'h00; mem[154] = 8'h00; mem[155] = 8'h9E;
        mem[156] = 8'h00; mem[157] = 8'h00; mem[158] = 8'h00; mem[159] = 8'hA1;
        mem[160] = 8'h00; mem[161] = 8'h00; mem[162] = 8'h00; mem[163] = 8'hA5;
        mem[164] = 8'h00; mem[165] = 8'h00; mem[166] = 8'h00; mem[167] = 8'hA8;
        mem[168] = 8'h00; mem[169] = 8'h00; mem[170] = 8'h00; mem[171] = 8'hAB;
        mem[172] = 8'h00; mem[173] = 8'h00; mem[174] = 8'h00; mem[175] = 8'hAF;
        mem[176] = 8'h00; mem[177] = 8'h00; mem[178] = 8'h00; mem[179] = 8'hB2;
        mem[180] = 8'h00; mem[181] = 8'h00; mem[182] = 8'h00; mem[183] = 8'hB5;
        mem[184] = 8'h00; mem[185] = 8'h00; mem[186] = 8'h00; mem[187] = 8'hB8;
        mem[188] = 8'h00; mem[189] = 8'h00; mem[190] = 8'h00; mem[191] = 8'hBB;
        mem[192] = 8'h00; mem[193] = 8'h00; mem[194] = 8'h00; mem[195] = 8'hBE;
        mem[196] = 8'h00; mem[197] = 8'h00; mem[198] = 8'h00; mem[199] = 8'hC1;
        mem[200] = 8'h00; mem[201] = 8'h00; mem[202] = 8'h00; mem[203] = 8'hC4;
        mem[204] = 8'h00; mem[205] = 8'h00; mem[206] = 8'h00; mem[207] = 8'hC7;
        mem[208] = 8'h00; mem[209] = 8'h00; mem[210] = 8'h00; mem[211] = 8'hCA;
        mem[212] = 8'h00; mem[213] = 8'h00; mem[214] = 8'h00; mem[215] = 8'hCC;
        mem[216] = 8'h00; mem[217] = 8'h00; mem[218] = 8'h00; mem[219] = 8'hCF;
        mem[220] = 8'h00; mem[221] = 8'h00; mem[222] = 8'h00; mem[223] = 8'hD2;
        mem[224] = 8'h00; mem[225] = 8'h00; mem[226] = 8'h00; mem[227] = 8'hD4;
        mem[228] = 8'h00; mem[229] = 8'h00; mem[230] = 8'h00; mem[231] = 8'hD7;
        mem[232] = 8'h00; mem[233] = 8'h00; mem[234] = 8'h00; mem[235] = 8'hD9;
        mem[236] = 8'h00; mem[237] = 8'h00; mem[238] = 8'h00; mem[239] = 8'hDB;
        mem[240] = 8'h00; mem[241] = 8'h00; mem[242] = 8'h00; mem[243] = 8'hDE;
        mem[244] = 8'h00; mem[245] = 8'h00; mem[246] = 8'h00; mem[247] = 8'hE0;
        mem[248] = 8'h00; mem[249] = 8'h00; mem[250] = 8'h00; mem[251] = 8'hE2;
        mem[252] = 8'h00; mem[253] = 8'h00; mem[254] = 8'h00; mem[255] = 8'hE4;
        mem[256] = 8'h00; mem[257] = 8'h00; mem[258] = 8'h00; mem[259] = 8'hE6;
        mem[260] = 8'h00; mem[261] = 8'h00; mem[262] = 8'h00; mem[263] = 8'hE8;
        mem[264] = 8'h00; mem[265] = 8'h00; mem[266] = 8'h00; mem[267] = 8'hEA;
        mem[268] = 8'h00; mem[269] = 8'h00; mem[270] = 8'h00; mem[271] = 8'hEC;
        mem[272] = 8'h00; mem[273] = 8'h00; mem[274] = 8'h00; mem[275] = 8'hED;
        mem[276] = 8'h00; mem[277] = 8'h00; mem[278] = 8'h00; mem[279] = 8'hEF;
        mem[280] = 8'h00; mem[281] = 8'h00; mem[282] = 8'h00; mem[283] = 8'hF1;
        mem[284] = 8'h00; mem[285] = 8'h00; mem[286] = 8'h00; mem[287] = 8'hF2;
        mem[288] = 8'h00; mem[289] = 8'h00; mem[290] = 8'h00; mem[291] = 8'hF3;
        mem[292] = 8'h00; mem[293] = 8'h00; mem[294] = 8'h00; mem[295] = 8'hF5;
        mem[296] = 8'h00; mem[297] = 8'h00; mem[298] = 8'h00; mem[299] = 8'hF6;
        mem[300] = 8'h00; mem[301] = 8'h00; mem[302] = 8'h00; mem[303] = 8'hF7;
        mem[304] = 8'h00; mem[305] = 8'h00; mem[306] = 8'h00; mem[307] = 8'hF8;
        mem[308] = 8'h00; mem[309] = 8'h00; mem[310] = 8'h00; mem[311] = 8'hF9;
        mem[312] = 8'h00; mem[313] = 8'h00; mem[314] = 8'h00; mem[315] = 8'hFA;
        mem[316] = 8'h00; mem[317] = 8'h00; mem[318] = 8'h00; mem[319] = 8'hFB;
        mem[320] = 8'h00; mem[321] = 8'h00; mem[322] = 8'h00; mem[323] = 8'hFC;
        mem[324] = 8'h00; mem[325] = 8'h00; mem[326] = 8'h00; mem[327] = 8'hFD;
        mem[328] = 8'h00; mem[329] = 8'h00; mem[330] = 8'h00; mem[331] = 8'hFE;
        mem[332] = 8'h00; mem[333] = 8'h00; mem[334] = 8'h00; mem[335] = 8'hFE;
        mem[336] = 8'h00; mem[337] = 8'h00; mem[338] = 8'h00; mem[339] = 8'hFF;
        mem[340] = 8'h00; mem[341] = 8'h00; mem[342] = 8'h00; mem[343] = 8'hFF;
        mem[344] = 8'h00; mem[345] = 8'h00; mem[346] = 8'h00; mem[347] = 8'hFF;
        mem[348] = 8'h00; mem[349] = 8'h00; mem[350] = 8'h01; mem[351] = 8'h00;
        mem[352] = 8'h00; mem[353] = 8'h00; mem[354] = 8'h01; mem[355] = 8'h00;
        mem[356] = 8'h00; mem[357] = 8'h00; mem[358] = 8'h01; mem[359] = 8'h00;
        mem[360] = 8'h00; mem[361] = 8'h00; mem[362] = 8'h01; mem[363] = 8'h00;
        mem[364] = 8'h00; mem[365] = 8'h00; mem[366] = 8'h01; mem[367] = 8'h00;
        mem[368] = 8'h00; mem[369] = 8'h00; mem[370] = 8'h01; mem[371] = 8'h00;
        mem[372] = 8'h00; mem[373] = 8'h00; mem[374] = 8'h01; mem[375] = 8'h00;
        mem[376] = 8'h00; mem[377] = 8'h00; mem[378] = 8'h00; mem[379] = 8'hFF;
        mem[380] = 8'h00; mem[381] = 8'h00; mem[382] = 8'h00; mem[383] = 8'hFF;
        mem[384] = 8'h00; mem[385] = 8'h00; mem[386] = 8'h00; mem[387] = 8'hFF;
        mem[388] = 8'h00; mem[389] = 8'h00; mem[390] = 8'h00; mem[391] = 8'hFE;
        mem[392] = 8'h00; mem[393] = 8'h00; mem[394] = 8'h00; mem[395] = 8'hFE;
        mem[396] = 8'h00; mem[397] = 8'h00; mem[398] = 8'h00; mem[399] = 8'hFD;
        mem[400] = 8'h00; mem[401] = 8'h00; mem[402] = 8'h00; mem[403] = 8'hFC;
        mem[404] = 8'h00; mem[405] = 8'h00; mem[406] = 8'h00; mem[407] = 8'hFB;
        mem[408] = 8'h00; mem[409] = 8'h00; mem[410] = 8'h00; mem[411] = 8'hFA;
        mem[412] = 8'h00; mem[413] = 8'h00; mem[414] = 8'h00; mem[415] = 8'hF9;
        mem[416] = 8'h00; mem[417] = 8'h00; mem[418] = 8'h00; mem[419] = 8'hF8;
        mem[420] = 8'h00; mem[421] = 8'h00; mem[422] = 8'h00; mem[423] = 8'hF7;
        mem[424] = 8'h00; mem[425] = 8'h00; mem[426] = 8'h00; mem[427] = 8'hF6;
        mem[428] = 8'h00; mem[429] = 8'h00; mem[430] = 8'h00; mem[431] = 8'hF5;
        mem[432] = 8'h00; mem[433] = 8'h00; mem[434] = 8'h00; mem[435] = 8'hF3;
        mem[436] = 8'h00; mem[437] = 8'h00; mem[438] = 8'h00; mem[439] = 8'hF2;
        mem[440] = 8'h00; mem[441] = 8'h00; mem[442] = 8'h00; mem[443] = 8'hF1;
        mem[444] = 8'h00; mem[445] = 8'h00; mem[446] = 8'h00; mem[447] = 8'hEF;
        mem[448] = 8'h00; mem[449] = 8'h00; mem[450] = 8'h00; mem[451] = 8'hED;
        mem[452] = 8'h00; mem[453] = 8'h00; mem[454] = 8'h00; mem[455] = 8'hEC;
        mem[456] = 8'h00; mem[457] = 8'h00; mem[458] = 8'h00; mem[459] = 8'hEA;
        mem[460] = 8'h00; mem[461] = 8'h00; mem[462] = 8'h00; mem[463] = 8'hE8;
        mem[464] = 8'h00; mem[465] = 8'h00; mem[466] = 8'h00; mem[467] = 8'hE6;
        mem[468] = 8'h00; mem[469] = 8'h00; mem[470] = 8'h00; mem[471] = 8'hE4;
        mem[472] = 8'h00; mem[473] = 8'h00; mem[474] = 8'h00; mem[475] = 8'hE2;
        mem[476] = 8'h00; mem[477] = 8'h00; mem[478] = 8'h00; mem[479] = 8'hE0;
        mem[480] = 8'h00; mem[481] = 8'h00; mem[482] = 8'h00; mem[483] = 8'hDE;
        mem[484] = 8'h00; mem[485] = 8'h00; mem[486] = 8'h00; mem[487] = 8'hDB;
        mem[488] = 8'h00; mem[489] = 8'h00; mem[490] = 8'h00; mem[491] = 8'hD9;
        mem[492] = 8'h00; mem[493] = 8'h00; mem[494] = 8'h00; mem[495] = 8'hD7;
        mem[496] = 8'h00; mem[497] = 8'h00; mem[498] = 8'h00; mem[499] = 8'hD4;
        mem[500] = 8'h00; mem[501] = 8'h00; mem[502] = 8'h00; mem[503] = 8'hD2;
        mem[504] = 8'h00; mem[505] = 8'h00; mem[506] = 8'h00; mem[507] = 8'hCF;
        mem[508] = 8'h00; mem[509] = 8'h00; mem[510] = 8'h00; mem[511] = 8'hCC;
        mem[512] = 8'h00; mem[513] = 8'h00; mem[514] = 8'h00; mem[515] = 8'hCA;
        mem[516] = 8'h00; mem[517] = 8'h00; mem[518] = 8'h00; mem[519] = 8'hC7;
        mem[520] = 8'h00; mem[521] = 8'h00; mem[522] = 8'h00; mem[523] = 8'hC4;
        mem[524] = 8'h00; mem[525] = 8'h00; mem[526] = 8'h00; mem[527] = 8'hC1;
        mem[528] = 8'h00; mem[529] = 8'h00; mem[530] = 8'h00; mem[531] = 8'hBE;
        mem[532] = 8'h00; mem[533] = 8'h00; mem[534] = 8'h00; mem[535] = 8'hBB;
        mem[536] = 8'h00; mem[537] = 8'h00; mem[538] = 8'h00; mem[539] = 8'hB8;
        mem[540] = 8'h00; mem[541] = 8'h00; mem[542] = 8'h00; mem[543] = 8'hB5;
        mem[544] = 8'h00; mem[545] = 8'h00; mem[546] = 8'h00; mem[547] = 8'hB2;
        mem[548] = 8'h00; mem[549] = 8'h00; mem[550] = 8'h00; mem[551] = 8'hAF;
        mem[552] = 8'h00; mem[553] = 8'h00; mem[554] = 8'h00; mem[555] = 8'hAB;
        mem[556] = 8'h00; mem[557] = 8'h00; mem[558] = 8'h00; mem[559] = 8'hA8;
        mem[560] = 8'h00; mem[561] = 8'h00; mem[562] = 8'h00; mem[563] = 8'hA5;
        mem[564] = 8'h00; mem[565] = 8'h00; mem[566] = 8'h00; mem[567] = 8'hA1;
        mem[568] = 8'h00; mem[569] = 8'h00; mem[570] = 8'h00; mem[571] = 8'h9E;
        mem[572] = 8'h00; mem[573] = 8'h00; mem[574] = 8'h00; mem[575] = 8'h9A;
        mem[576] = 8'h00; mem[577] = 8'h00; mem[578] = 8'h00; mem[579] = 8'h96;
        mem[580] = 8'h00; mem[581] = 8'h00; mem[582] = 8'h00; mem[583] = 8'h93;
        mem[584] = 8'h00; mem[585] = 8'h00; mem[586] = 8'h00; mem[587] = 8'h8F;
        mem[588] = 8'h00; mem[589] = 8'h00; mem[590] = 8'h00; mem[591] = 8'h8B;
        mem[592] = 8'h00; mem[593] = 8'h00; mem[594] = 8'h00; mem[595] = 8'h88;
        mem[596] = 8'h00; mem[597] = 8'h00; mem[598] = 8'h00; mem[599] = 8'h84;
        mem[600] = 8'h00; mem[601] = 8'h00; mem[602] = 8'h00; mem[603] = 8'h80;
        mem[604] = 8'h00; mem[605] = 8'h00; mem[606] = 8'h00; mem[607] = 8'h7C;
        mem[608] = 8'h00; mem[609] = 8'h00; mem[610] = 8'h00; mem[611] = 8'h78;
        mem[612] = 8'h00; mem[613] = 8'h00; mem[614] = 8'h00; mem[615] = 8'h74;
        mem[616] = 8'h00; mem[617] = 8'h00; mem[618] = 8'h00; mem[619] = 8'h70;
        mem[620] = 8'h00; mem[621] = 8'h00; mem[622] = 8'h00; mem[623] = 8'h6C;
        mem[624] = 8'h00; mem[625] = 8'h00; mem[626] = 8'h00; mem[627] = 8'h68;
        mem[628] = 8'h00; mem[629] = 8'h00; mem[630] = 8'h00; mem[631] = 8'h64;
        mem[632] = 8'h00; mem[633] = 8'h00; mem[634] = 8'h00; mem[635] = 8'h60;
        mem[636] = 8'h00; mem[637] = 8'h00; mem[638] = 8'h00; mem[639] = 8'h5C;
        mem[640] = 8'h00; mem[641] = 8'h00; mem[642] = 8'h00; mem[643] = 8'h58;
        mem[644] = 8'h00; mem[645] = 8'h00; mem[646] = 8'h00; mem[647] = 8'h53;
        mem[648] = 8'h00; mem[649] = 8'h00; mem[650] = 8'h00; mem[651] = 8'h4F;
        mem[652] = 8'h00; mem[653] = 8'h00; mem[654] = 8'h00; mem[655] = 8'h4B;
        mem[656] = 8'h00; mem[657] = 8'h00; mem[658] = 8'h00; mem[659] = 8'h47;
        mem[660] = 8'h00; mem[661] = 8'h00; mem[662] = 8'h00; mem[663] = 8'h42;
        mem[664] = 8'h00; mem[665] = 8'h00; mem[666] = 8'h00; mem[667] = 8'h3E;
        mem[668] = 8'h00; mem[669] = 8'h00; mem[670] = 8'h00; mem[671] = 8'h3A;
        mem[672] = 8'h00; mem[673] = 8'h00; mem[674] = 8'h00; mem[675] = 8'h35;
        mem[676] = 8'h00; mem[677] = 8'h00; mem[678] = 8'h00; mem[679] = 8'h31;
        mem[680] = 8'h00; mem[681] = 8'h00; mem[682] = 8'h00; mem[683] = 8'h2C;
        mem[684] = 8'h00; mem[685] = 8'h00; mem[686] = 8'h00; mem[687] = 8'h28;
        mem[688] = 8'h00; mem[689] = 8'h00; mem[690] = 8'h00; mem[691] = 8'h24;
        mem[692] = 8'h00; mem[693] = 8'h00; mem[694] = 8'h00; mem[695] = 8'h1F;
        mem[696] = 8'h00; mem[697] = 8'h00; mem[698] = 8'h00; mem[699] = 8'h1B;
        mem[700] = 8'h00; mem[701] = 8'h00; mem[702] = 8'h00; mem[703] = 8'h16;
        mem[704] = 8'h00; mem[705] = 8'h00; mem[706] = 8'h00; mem[707] = 8'h12;
        mem[708] = 8'h00; mem[709] = 8'h00; mem[710] = 8'h00; mem[711] = 8'h0D;
        mem[712] = 8'h00; mem[713] = 8'h00; mem[714] = 8'h00; mem[715] = 8'h09;
        mem[716] = 8'h00; mem[717] = 8'h00; mem[718] = 8'h00; mem[719] = 8'h04;
        mem[720] = 8'h00; mem[721] = 8'h00; mem[722] = 8'h00; mem[723] = 8'h00;
        mem[724] = 8'hFF; mem[725] = 8'hFF; mem[726] = 8'hFF; mem[727] = 8'hFC;
        mem[728] = 8'hFF; mem[729] = 8'hFF; mem[730] = 8'hFF; mem[731] = 8'hF7;
        mem[732] = 8'hFF; mem[733] = 8'hFF; mem[734] = 8'hFF; mem[735] = 8'hF3;
        mem[736] = 8'hFF; mem[737] = 8'hFF; mem[738] = 8'hFF; mem[739] = 8'hEE;
        mem[740] = 8'hFF; mem[741] = 8'hFF; mem[742] = 8'hFF; mem[743] = 8'hEA;
        mem[744] = 8'hFF; mem[745] = 8'hFF; mem[746] = 8'hFF; mem[747] = 8'hE5;
        mem[748] = 8'hFF; mem[749] = 8'hFF; mem[750] = 8'hFF; mem[751] = 8'hE1;
        mem[752] = 8'hFF; mem[753] = 8'hFF; mem[754] = 8'hFF; mem[755] = 8'hDC;
        mem[756] = 8'hFF; mem[757] = 8'hFF; mem[758] = 8'hFF; mem[759] = 8'hD8;
        mem[760] = 8'hFF; mem[761] = 8'hFF; mem[762] = 8'hFF; mem[763] = 8'hD4;
        mem[764] = 8'hFF; mem[765] = 8'hFF; mem[766] = 8'hFF; mem[767] = 8'hCF;
        mem[768] = 8'hFF; mem[769] = 8'hFF; mem[770] = 8'hFF; mem[771] = 8'hCB;
        mem[772] = 8'hFF; mem[773] = 8'hFF; mem[774] = 8'hFF; mem[775] = 8'hC6;
        mem[776] = 8'hFF; mem[777] = 8'hFF; mem[778] = 8'hFF; mem[779] = 8'hC2;
        mem[780] = 8'hFF; mem[781] = 8'hFF; mem[782] = 8'hFF; mem[783] = 8'hBE;
        mem[784] = 8'hFF; mem[785] = 8'hFF; mem[786] = 8'hFF; mem[787] = 8'hB9;
        mem[788] = 8'hFF; mem[789] = 8'hFF; mem[790] = 8'hFF; mem[791] = 8'hB5;
        mem[792] = 8'hFF; mem[793] = 8'hFF; mem[794] = 8'hFF; mem[795] = 8'hB1;
        mem[796] = 8'hFF; mem[797] = 8'hFF; mem[798] = 8'hFF; mem[799] = 8'hAD;
        mem[800] = 8'hFF; mem[801] = 8'hFF; mem[802] = 8'hFF; mem[803] = 8'hA8;
        mem[804] = 8'hFF; mem[805] = 8'hFF; mem[806] = 8'hFF; mem[807] = 8'hA4;
        mem[808] = 8'hFF; mem[809] = 8'hFF; mem[810] = 8'hFF; mem[811] = 8'hA0;
        mem[812] = 8'hFF; mem[813] = 8'hFF; mem[814] = 8'hFF; mem[815] = 8'h9C;
        mem[816] = 8'hFF; mem[817] = 8'hFF; mem[818] = 8'hFF; mem[819] = 8'h98;
        mem[820] = 8'hFF; mem[821] = 8'hFF; mem[822] = 8'hFF; mem[823] = 8'h94;
        mem[824] = 8'hFF; mem[825] = 8'hFF; mem[826] = 8'hFF; mem[827] = 8'h90;
        mem[828] = 8'hFF; mem[829] = 8'hFF; mem[830] = 8'hFF; mem[831] = 8'h8C;
        mem[832] = 8'hFF; mem[833] = 8'hFF; mem[834] = 8'hFF; mem[835] = 8'h88;
        mem[836] = 8'hFF; mem[837] = 8'hFF; mem[838] = 8'hFF; mem[839] = 8'h84;
        mem[840] = 8'hFF; mem[841] = 8'hFF; mem[842] = 8'hFF; mem[843] = 8'h80;
        mem[844] = 8'hFF; mem[845] = 8'hFF; mem[846] = 8'hFF; mem[847] = 8'h7C;
        mem[848] = 8'hFF; mem[849] = 8'hFF; mem[850] = 8'hFF; mem[851] = 8'h78;
        mem[852] = 8'hFF; mem[853] = 8'hFF; mem[854] = 8'hFF; mem[855] = 8'h75;
        mem[856] = 8'hFF; mem[857] = 8'hFF; mem[858] = 8'hFF; mem[859] = 8'h71;
        mem[860] = 8'hFF; mem[861] = 8'hFF; mem[862] = 8'hFF; mem[863] = 8'h6D;
        mem[864] = 8'hFF; mem[865] = 8'hFF; mem[866] = 8'hFF; mem[867] = 8'h6A;
        mem[868] = 8'hFF; mem[869] = 8'hFF; mem[870] = 8'hFF; mem[871] = 8'h66;
        mem[872] = 8'hFF; mem[873] = 8'hFF; mem[874] = 8'hFF; mem[875] = 8'h62;
        mem[876] = 8'hFF; mem[877] = 8'hFF; mem[878] = 8'hFF; mem[879] = 8'h5F;
        mem[880] = 8'hFF; mem[881] = 8'hFF; mem[882] = 8'hFF; mem[883] = 8'h5B;
        mem[884] = 8'hFF; mem[885] = 8'hFF; mem[886] = 8'hFF; mem[887] = 8'h58;
        mem[888] = 8'hFF; mem[889] = 8'hFF; mem[890] = 8'hFF; mem[891] = 8'h55;
        mem[892] = 8'hFF; mem[893] = 8'hFF; mem[894] = 8'hFF; mem[895] = 8'h51;
        mem[896] = 8'hFF; mem[897] = 8'hFF; mem[898] = 8'hFF; mem[899] = 8'h4E;
        mem[900] = 8'hFF; mem[901] = 8'hFF; mem[902] = 8'hFF; mem[903] = 8'h4B;
        mem[904] = 8'hFF; mem[905] = 8'hFF; mem[906] = 8'hFF; mem[907] = 8'h48;
        mem[908] = 8'hFF; mem[909] = 8'hFF; mem[910] = 8'hFF; mem[911] = 8'h45;
        mem[912] = 8'hFF; mem[913] = 8'hFF; mem[914] = 8'hFF; mem[915] = 8'h42;
        mem[916] = 8'hFF; mem[917] = 8'hFF; mem[918] = 8'hFF; mem[919] = 8'h3F;
        mem[920] = 8'hFF; mem[921] = 8'hFF; mem[922] = 8'hFF; mem[923] = 8'h3C;
        mem[924] = 8'hFF; mem[925] = 8'hFF; mem[926] = 8'hFF; mem[927] = 8'h39;
        mem[928] = 8'hFF; mem[929] = 8'hFF; mem[930] = 8'hFF; mem[931] = 8'h36;
        mem[932] = 8'hFF; mem[933] = 8'hFF; mem[934] = 8'hFF; mem[935] = 8'h34;
        mem[936] = 8'hFF; mem[937] = 8'hFF; mem[938] = 8'hFF; mem[939] = 8'h31;
        mem[940] = 8'hFF; mem[941] = 8'hFF; mem[942] = 8'hFF; mem[943] = 8'h2E;
        mem[944] = 8'hFF; mem[945] = 8'hFF; mem[946] = 8'hFF; mem[947] = 8'h2C;
        mem[948] = 8'hFF; mem[949] = 8'hFF; mem[950] = 8'hFF; mem[951] = 8'h29;
        mem[952] = 8'hFF; mem[953] = 8'hFF; mem[954] = 8'hFF; mem[955] = 8'h27;
        mem[956] = 8'hFF; mem[957] = 8'hFF; mem[958] = 8'hFF; mem[959] = 8'h25;
        mem[960] = 8'hFF; mem[961] = 8'hFF; mem[962] = 8'hFF; mem[963] = 8'h22;
        mem[964] = 8'hFF; mem[965] = 8'hFF; mem[966] = 8'hFF; mem[967] = 8'h20;
        mem[968] = 8'hFF; mem[969] = 8'hFF; mem[970] = 8'hFF; mem[971] = 8'h1E;
        mem[972] = 8'hFF; mem[973] = 8'hFF; mem[974] = 8'hFF; mem[975] = 8'h1C;
        mem[976] = 8'hFF; mem[977] = 8'hFF; mem[978] = 8'hFF; mem[979] = 8'h1A;
        mem[980] = 8'hFF; mem[981] = 8'hFF; mem[982] = 8'hFF; mem[983] = 8'h18;
        mem[984] = 8'hFF; mem[985] = 8'hFF; mem[986] = 8'hFF; mem[987] = 8'h16;
        mem[988] = 8'hFF; mem[989] = 8'hFF; mem[990] = 8'hFF; mem[991] = 8'h14;
        mem[992] = 8'hFF; mem[993] = 8'hFF; mem[994] = 8'hFF; mem[995] = 8'h13;
        mem[996] = 8'hFF; mem[997] = 8'hFF; mem[998] = 8'hFF; mem[999] = 8'h11;
        mem[1000] = 8'hFF; mem[1001] = 8'hFF; mem[1002] = 8'hFF; mem[1003] = 8'h0F;
        mem[1004] = 8'hFF; mem[1005] = 8'hFF; mem[1006] = 8'hFF; mem[1007] = 8'h0E;
        mem[1008] = 8'hFF; mem[1009] = 8'hFF; mem[1010] = 8'hFF; mem[1011] = 8'h0D;
        mem[1012] = 8'hFF; mem[1013] = 8'hFF; mem[1014] = 8'hFF; mem[1015] = 8'h0B;
        mem[1016] = 8'hFF; mem[1017] = 8'hFF; mem[1018] = 8'hFF; mem[1019] = 8'h0A;
        mem[1020] = 8'hFF; mem[1021] = 8'hFF; mem[1022] = 8'hFF; mem[1023] = 8'h09;
        mem[1024] = 8'hFF; mem[1025] = 8'hFF; mem[1026] = 8'hFF; mem[1027] = 8'h08;
        mem[1028] = 8'hFF; mem[1029] = 8'hFF; mem[1030] = 8'hFF; mem[1031] = 8'h07;
        mem[1032] = 8'hFF; mem[1033] = 8'hFF; mem[1034] = 8'hFF; mem[1035] = 8'h06;
        mem[1036] = 8'hFF; mem[1037] = 8'hFF; mem[1038] = 8'hFF; mem[1039] = 8'h05;
        mem[1040] = 8'hFF; mem[1041] = 8'hFF; mem[1042] = 8'hFF; mem[1043] = 8'h04;
        mem[1044] = 8'hFF; mem[1045] = 8'hFF; mem[1046] = 8'hFF; mem[1047] = 8'h03;
        mem[1048] = 8'hFF; mem[1049] = 8'hFF; mem[1050] = 8'hFF; mem[1051] = 8'h02;
        mem[1052] = 8'hFF; mem[1053] = 8'hFF; mem[1054] = 8'hFF; mem[1055] = 8'h02;
        mem[1056] = 8'hFF; mem[1057] = 8'hFF; mem[1058] = 8'hFF; mem[1059] = 8'h01;
        mem[1060] = 8'hFF; mem[1061] = 8'hFF; mem[1062] = 8'hFF; mem[1063] = 8'h01;
        mem[1064] = 8'hFF; mem[1065] = 8'hFF; mem[1066] = 8'hFF; mem[1067] = 8'h01;
        mem[1068] = 8'hFF; mem[1069] = 8'hFF; mem[1070] = 8'hFF; mem[1071] = 8'h00;
        mem[1072] = 8'hFF; mem[1073] = 8'hFF; mem[1074] = 8'hFF; mem[1075] = 8'h00;
        mem[1076] = 8'hFF; mem[1077] = 8'hFF; mem[1078] = 8'hFF; mem[1079] = 8'h00;
        mem[1080] = 8'hFF; mem[1081] = 8'hFF; mem[1082] = 8'hFF; mem[1083] = 8'h00;
        mem[1084] = 8'hFF; mem[1085] = 8'hFF; mem[1086] = 8'hFF; mem[1087] = 8'h00;
        mem[1088] = 8'hFF; mem[1089] = 8'hFF; mem[1090] = 8'hFF; mem[1091] = 8'h00;
        mem[1092] = 8'hFF; mem[1093] = 8'hFF; mem[1094] = 8'hFF; mem[1095] = 8'h00;
        mem[1096] = 8'hFF; mem[1097] = 8'hFF; mem[1098] = 8'hFF; mem[1099] = 8'h01;
        mem[1100] = 8'hFF; mem[1101] = 8'hFF; mem[1102] = 8'hFF; mem[1103] = 8'h01;
        mem[1104] = 8'hFF; mem[1105] = 8'hFF; mem[1106] = 8'hFF; mem[1107] = 8'h01;
        mem[1108] = 8'hFF; mem[1109] = 8'hFF; mem[1110] = 8'hFF; mem[1111] = 8'h02;
        mem[1112] = 8'hFF; mem[1113] = 8'hFF; mem[1114] = 8'hFF; mem[1115] = 8'h02;
        mem[1116] = 8'hFF; mem[1117] = 8'hFF; mem[1118] = 8'hFF; mem[1119] = 8'h03;
        mem[1120] = 8'hFF; mem[1121] = 8'hFF; mem[1122] = 8'hFF; mem[1123] = 8'h04;
        mem[1124] = 8'hFF; mem[1125] = 8'hFF; mem[1126] = 8'hFF; mem[1127] = 8'h05;
        mem[1128] = 8'hFF; mem[1129] = 8'hFF; mem[1130] = 8'hFF; mem[1131] = 8'h06;
        mem[1132] = 8'hFF; mem[1133] = 8'hFF; mem[1134] = 8'hFF; mem[1135] = 8'h07;
        mem[1136] = 8'hFF; mem[1137] = 8'hFF; mem[1138] = 8'hFF; mem[1139] = 8'h08;
        mem[1140] = 8'hFF; mem[1141] = 8'hFF; mem[1142] = 8'hFF; mem[1143] = 8'h09;
        mem[1144] = 8'hFF; mem[1145] = 8'hFF; mem[1146] = 8'hFF; mem[1147] = 8'h0A;
        mem[1148] = 8'hFF; mem[1149] = 8'hFF; mem[1150] = 8'hFF; mem[1151] = 8'h0B;
        mem[1152] = 8'hFF; mem[1153] = 8'hFF; mem[1154] = 8'hFF; mem[1155] = 8'h0D;
        mem[1156] = 8'hFF; mem[1157] = 8'hFF; mem[1158] = 8'hFF; mem[1159] = 8'h0E;
        mem[1160] = 8'hFF; mem[1161] = 8'hFF; mem[1162] = 8'hFF; mem[1163] = 8'h0F;
        mem[1164] = 8'hFF; mem[1165] = 8'hFF; mem[1166] = 8'hFF; mem[1167] = 8'h11;
        mem[1168] = 8'hFF; mem[1169] = 8'hFF; mem[1170] = 8'hFF; mem[1171] = 8'h13;
        mem[1172] = 8'hFF; mem[1173] = 8'hFF; mem[1174] = 8'hFF; mem[1175] = 8'h14;
        mem[1176] = 8'hFF; mem[1177] = 8'hFF; mem[1178] = 8'hFF; mem[1179] = 8'h16;
        mem[1180] = 8'hFF; mem[1181] = 8'hFF; mem[1182] = 8'hFF; mem[1183] = 8'h18;
        mem[1184] = 8'hFF; mem[1185] = 8'hFF; mem[1186] = 8'hFF; mem[1187] = 8'h1A;
        mem[1188] = 8'hFF; mem[1189] = 8'hFF; mem[1190] = 8'hFF; mem[1191] = 8'h1C;
        mem[1192] = 8'hFF; mem[1193] = 8'hFF; mem[1194] = 8'hFF; mem[1195] = 8'h1E;
        mem[1196] = 8'hFF; mem[1197] = 8'hFF; mem[1198] = 8'hFF; mem[1199] = 8'h20;
        mem[1200] = 8'hFF; mem[1201] = 8'hFF; mem[1202] = 8'hFF; mem[1203] = 8'h22;
        mem[1204] = 8'hFF; mem[1205] = 8'hFF; mem[1206] = 8'hFF; mem[1207] = 8'h25;
        mem[1208] = 8'hFF; mem[1209] = 8'hFF; mem[1210] = 8'hFF; mem[1211] = 8'h27;
        mem[1212] = 8'hFF; mem[1213] = 8'hFF; mem[1214] = 8'hFF; mem[1215] = 8'h29;
        mem[1216] = 8'hFF; mem[1217] = 8'hFF; mem[1218] = 8'hFF; mem[1219] = 8'h2C;
        mem[1220] = 8'hFF; mem[1221] = 8'hFF; mem[1222] = 8'hFF; mem[1223] = 8'h2E;
        mem[1224] = 8'hFF; mem[1225] = 8'hFF; mem[1226] = 8'hFF; mem[1227] = 8'h31;
        mem[1228] = 8'hFF; mem[1229] = 8'hFF; mem[1230] = 8'hFF; mem[1231] = 8'h34;
        mem[1232] = 8'hFF; mem[1233] = 8'hFF; mem[1234] = 8'hFF; mem[1235] = 8'h36;
        mem[1236] = 8'hFF; mem[1237] = 8'hFF; mem[1238] = 8'hFF; mem[1239] = 8'h39;
        mem[1240] = 8'hFF; mem[1241] = 8'hFF; mem[1242] = 8'hFF; mem[1243] = 8'h3C;
        mem[1244] = 8'hFF; mem[1245] = 8'hFF; mem[1246] = 8'hFF; mem[1247] = 8'h3F;
        mem[1248] = 8'hFF; mem[1249] = 8'hFF; mem[1250] = 8'hFF; mem[1251] = 8'h42;
        mem[1252] = 8'hFF; mem[1253] = 8'hFF; mem[1254] = 8'hFF; mem[1255] = 8'h45;
        mem[1256] = 8'hFF; mem[1257] = 8'hFF; mem[1258] = 8'hFF; mem[1259] = 8'h48;
        mem[1260] = 8'hFF; mem[1261] = 8'hFF; mem[1262] = 8'hFF; mem[1263] = 8'h4B;
        mem[1264] = 8'hFF; mem[1265] = 8'hFF; mem[1266] = 8'hFF; mem[1267] = 8'h4E;
        mem[1268] = 8'hFF; mem[1269] = 8'hFF; mem[1270] = 8'hFF; mem[1271] = 8'h51;
        mem[1272] = 8'hFF; mem[1273] = 8'hFF; mem[1274] = 8'hFF; mem[1275] = 8'h55;
        mem[1276] = 8'hFF; mem[1277] = 8'hFF; mem[1278] = 8'hFF; mem[1279] = 8'h58;
        mem[1280] = 8'hFF; mem[1281] = 8'hFF; mem[1282] = 8'hFF; mem[1283] = 8'h5B;
        mem[1284] = 8'hFF; mem[1285] = 8'hFF; mem[1286] = 8'hFF; mem[1287] = 8'h5F;
        mem[1288] = 8'hFF; mem[1289] = 8'hFF; mem[1290] = 8'hFF; mem[1291] = 8'h62;
        mem[1292] = 8'hFF; mem[1293] = 8'hFF; mem[1294] = 8'hFF; mem[1295] = 8'h66;
        mem[1296] = 8'hFF; mem[1297] = 8'hFF; mem[1298] = 8'hFF; mem[1299] = 8'h6A;
        mem[1300] = 8'hFF; mem[1301] = 8'hFF; mem[1302] = 8'hFF; mem[1303] = 8'h6D;
        mem[1304] = 8'hFF; mem[1305] = 8'hFF; mem[1306] = 8'hFF; mem[1307] = 8'h71;
        mem[1308] = 8'hFF; mem[1309] = 8'hFF; mem[1310] = 8'hFF; mem[1311] = 8'h75;
        mem[1312] = 8'hFF; mem[1313] = 8'hFF; mem[1314] = 8'hFF; mem[1315] = 8'h78;
        mem[1316] = 8'hFF; mem[1317] = 8'hFF; mem[1318] = 8'hFF; mem[1319] = 8'h7C;
        mem[1320] = 8'hFF; mem[1321] = 8'hFF; mem[1322] = 8'hFF; mem[1323] = 8'h80;
        mem[1324] = 8'hFF; mem[1325] = 8'hFF; mem[1326] = 8'hFF; mem[1327] = 8'h84;
        mem[1328] = 8'hFF; mem[1329] = 8'hFF; mem[1330] = 8'hFF; mem[1331] = 8'h88;
        mem[1332] = 8'hFF; mem[1333] = 8'hFF; mem[1334] = 8'hFF; mem[1335] = 8'h8C;
        mem[1336] = 8'hFF; mem[1337] = 8'hFF; mem[1338] = 8'hFF; mem[1339] = 8'h90;
        mem[1340] = 8'hFF; mem[1341] = 8'hFF; mem[1342] = 8'hFF; mem[1343] = 8'h94;
        mem[1344] = 8'hFF; mem[1345] = 8'hFF; mem[1346] = 8'hFF; mem[1347] = 8'h98;
        mem[1348] = 8'hFF; mem[1349] = 8'hFF; mem[1350] = 8'hFF; mem[1351] = 8'h9C;
        mem[1352] = 8'hFF; mem[1353] = 8'hFF; mem[1354] = 8'hFF; mem[1355] = 8'hA0;
        mem[1356] = 8'hFF; mem[1357] = 8'hFF; mem[1358] = 8'hFF; mem[1359] = 8'hA4;
        mem[1360] = 8'hFF; mem[1361] = 8'hFF; mem[1362] = 8'hFF; mem[1363] = 8'hA8;
        mem[1364] = 8'hFF; mem[1365] = 8'hFF; mem[1366] = 8'hFF; mem[1367] = 8'hAD;
        mem[1368] = 8'hFF; mem[1369] = 8'hFF; mem[1370] = 8'hFF; mem[1371] = 8'hB1;
        mem[1372] = 8'hFF; mem[1373] = 8'hFF; mem[1374] = 8'hFF; mem[1375] = 8'hB5;
        mem[1376] = 8'hFF; mem[1377] = 8'hFF; mem[1378] = 8'hFF; mem[1379] = 8'hB9;
        mem[1380] = 8'hFF; mem[1381] = 8'hFF; mem[1382] = 8'hFF; mem[1383] = 8'hBE;
        mem[1384] = 8'hFF; mem[1385] = 8'hFF; mem[1386] = 8'hFF; mem[1387] = 8'hC2;
        mem[1388] = 8'hFF; mem[1389] = 8'hFF; mem[1390] = 8'hFF; mem[1391] = 8'hC6;
        mem[1392] = 8'hFF; mem[1393] = 8'hFF; mem[1394] = 8'hFF; mem[1395] = 8'hCB;
        mem[1396] = 8'hFF; mem[1397] = 8'hFF; mem[1398] = 8'hFF; mem[1399] = 8'hCF;
        mem[1400] = 8'hFF; mem[1401] = 8'hFF; mem[1402] = 8'hFF; mem[1403] = 8'hD4;
        mem[1404] = 8'hFF; mem[1405] = 8'hFF; mem[1406] = 8'hFF; mem[1407] = 8'hD8;
        mem[1408] = 8'hFF; mem[1409] = 8'hFF; mem[1410] = 8'hFF; mem[1411] = 8'hDC;
        mem[1412] = 8'hFF; mem[1413] = 8'hFF; mem[1414] = 8'hFF; mem[1415] = 8'hE1;
        mem[1416] = 8'hFF; mem[1417] = 8'hFF; mem[1418] = 8'hFF; mem[1419] = 8'hE5;
        mem[1420] = 8'hFF; mem[1421] = 8'hFF; mem[1422] = 8'hFF; mem[1423] = 8'hEA;
        mem[1424] = 8'hFF; mem[1425] = 8'hFF; mem[1426] = 8'hFF; mem[1427] = 8'hEE;
        mem[1428] = 8'hFF; mem[1429] = 8'hFF; mem[1430] = 8'hFF; mem[1431] = 8'hF3;
        mem[1432] = 8'hFF; mem[1433] = 8'hFF; mem[1434] = 8'hFF; mem[1435] = 8'hF7;
        mem[1436] = 8'hFF; mem[1437] = 8'hFF; mem[1438] = 8'hFF; mem[1439] = 8'hFC;
        mem[1440] = 8'h00; mem[1441] = 8'h00; mem[1442] = 8'h00; mem[1443] = 8'h00;
        // ---- Sine LUT end (0x05A3) ----

        // ---- Arena map (0x05A4-0x0733): word-packed 10x10 grid ----
        // Row 0 = north (top), Row 9 = south (bottom). 1=wall, 0=empty.
        mem[1444] = 8'h00; mem[1445] = 8'h00; mem[1446] = 8'h00; mem[1447] = 8'h01;
        mem[1448] = 8'h00; mem[1449] = 8'h00; mem[1450] = 8'h00; mem[1451] = 8'h01;
        mem[1452] = 8'h00; mem[1453] = 8'h00; mem[1454] = 8'h00; mem[1455] = 8'h01;
        mem[1456] = 8'h00; mem[1457] = 8'h00; mem[1458] = 8'h00; mem[1459] = 8'h01;
        mem[1460] = 8'h00; mem[1461] = 8'h00; mem[1462] = 8'h00; mem[1463] = 8'h01;
        mem[1464] = 8'h00; mem[1465] = 8'h00; mem[1466] = 8'h00; mem[1467] = 8'h01;
        mem[1468] = 8'h00; mem[1469] = 8'h00; mem[1470] = 8'h00; mem[1471] = 8'h01;
        mem[1472] = 8'h00; mem[1473] = 8'h00; mem[1474] = 8'h00; mem[1475] = 8'h01;
        mem[1476] = 8'h00; mem[1477] = 8'h00; mem[1478] = 8'h00; mem[1479] = 8'h01;
        mem[1480] = 8'h00; mem[1481] = 8'h00; mem[1482] = 8'h00; mem[1483] = 8'h01;
        mem[1484] = 8'h00; mem[1485] = 8'h00; mem[1486] = 8'h00; mem[1487] = 8'h01;
        mem[1488] = 8'h00; mem[1489] = 8'h00; mem[1490] = 8'h00; mem[1491] = 8'h00;
        mem[1492] = 8'h00; mem[1493] = 8'h00; mem[1494] = 8'h00; mem[1495] = 8'h00;
        mem[1496] = 8'h00; mem[1497] = 8'h00; mem[1498] = 8'h00; mem[1499] = 8'h00;
        mem[1500] = 8'h00; mem[1501] = 8'h00; mem[1502] = 8'h00; mem[1503] = 8'h00;
        mem[1504] = 8'h00; mem[1505] = 8'h00; mem[1506] = 8'h00; mem[1507] = 8'h00;
        mem[1508] = 8'h00; mem[1509] = 8'h00; mem[1510] = 8'h00; mem[1511] = 8'h00;
        mem[1512] = 8'h00; mem[1513] = 8'h00; mem[1514] = 8'h00; mem[1515] = 8'h00;
        mem[1516] = 8'h00; mem[1517] = 8'h00; mem[1518] = 8'h00; mem[1519] = 8'h00;
        mem[1520] = 8'h00; mem[1521] = 8'h00; mem[1522] = 8'h00; mem[1523] = 8'h01;
        mem[1524] = 8'h00; mem[1525] = 8'h00; mem[1526] = 8'h00; mem[1527] = 8'h01;
        mem[1528] = 8'h00; mem[1529] = 8'h00; mem[1530] = 8'h00; mem[1531] = 8'h00;
        mem[1532] = 8'h00; mem[1533] = 8'h00; mem[1534] = 8'h00; mem[1535] = 8'h00;
        mem[1536] = 8'h00; mem[1537] = 8'h00; mem[1538] = 8'h00; mem[1539] = 8'h00;
        mem[1540] = 8'h00; mem[1541] = 8'h00; mem[1542] = 8'h00; mem[1543] = 8'h00;
        mem[1544] = 8'h00; mem[1545] = 8'h00; mem[1546] = 8'h00; mem[1547] = 8'h00;
        mem[1548] = 8'h00; mem[1549] = 8'h00; mem[1550] = 8'h00; mem[1551] = 8'h00;
        mem[1552] = 8'h00; mem[1553] = 8'h00; mem[1554] = 8'h00; mem[1555] = 8'h00;
        mem[1556] = 8'h00; mem[1557] = 8'h00; mem[1558] = 8'h00; mem[1559] = 8'h00;
        mem[1560] = 8'h00; mem[1561] = 8'h00; mem[1562] = 8'h00; mem[1563] = 8'h01;
        mem[1564] = 8'h00; mem[1565] = 8'h00; mem[1566] = 8'h00; mem[1567] = 8'h01;
        mem[1568] = 8'h00; mem[1569] = 8'h00; mem[1570] = 8'h00; mem[1571] = 8'h00;
        mem[1572] = 8'h00; mem[1573] = 8'h00; mem[1574] = 8'h00; mem[1575] = 8'h00;
        mem[1576] = 8'h00; mem[1577] = 8'h00; mem[1578] = 8'h00; mem[1579] = 8'h01;
        mem[1580] = 8'h00; mem[1581] = 8'h00; mem[1582] = 8'h00; mem[1583] = 8'h01;
        mem[1584] = 8'h00; mem[1585] = 8'h00; mem[1586] = 8'h00; mem[1587] = 8'h01;
        mem[1588] = 8'h00; mem[1589] = 8'h00; mem[1590] = 8'h00; mem[1591] = 8'h00;
        mem[1592] = 8'h00; mem[1593] = 8'h00; mem[1594] = 8'h00; mem[1595] = 8'h00;
        mem[1596] = 8'h00; mem[1597] = 8'h00; mem[1598] = 8'h00; mem[1599] = 8'h00;
        mem[1600] = 8'h00; mem[1601] = 8'h00; mem[1602] = 8'h00; mem[1603] = 8'h01;
        mem[1604] = 8'h00; mem[1605] = 8'h00; mem[1606] = 8'h00; mem[1607] = 8'h01;
        mem[1608] = 8'h00; mem[1609] = 8'h00; mem[1610] = 8'h00; mem[1611] = 8'h00;
        mem[1612] = 8'h00; mem[1613] = 8'h00; mem[1614] = 8'h00; mem[1615] = 8'h00;
        mem[1616] = 8'h00; mem[1617] = 8'h00; mem[1618] = 8'h00; mem[1619] = 8'h00;
        mem[1620] = 8'h00; mem[1621] = 8'h00; mem[1622] = 8'h00; mem[1623] = 8'h00;
        mem[1624] = 8'h00; mem[1625] = 8'h00; mem[1626] = 8'h00; mem[1627] = 8'h00;
        mem[1628] = 8'h00; mem[1629] = 8'h00; mem[1630] = 8'h00; mem[1631] = 8'h00;
        mem[1632] = 8'h00; mem[1633] = 8'h00; mem[1634] = 8'h00; mem[1635] = 8'h00;
        mem[1636] = 8'h00; mem[1637] = 8'h00; mem[1638] = 8'h00; mem[1639] = 8'h00;
        mem[1640] = 8'h00; mem[1641] = 8'h00; mem[1642] = 8'h00; mem[1643] = 8'h01;
        mem[1644] = 8'h00; mem[1645] = 8'h00; mem[1646] = 8'h00; mem[1647] = 8'h01;
        mem[1648] = 8'h00; mem[1649] = 8'h00; mem[1650] = 8'h00; mem[1651] = 8'h00;
        mem[1652] = 8'h00; mem[1653] = 8'h00; mem[1654] = 8'h00; mem[1655] = 8'h00;
        mem[1656] = 8'h00; mem[1657] = 8'h00; mem[1658] = 8'h00; mem[1659] = 8'h00;
        mem[1660] = 8'h00; mem[1661] = 8'h00; mem[1662] = 8'h00; mem[1663] = 8'h00;
        mem[1664] = 8'h00; mem[1665] = 8'h00; mem[1666] = 8'h00; mem[1667] = 8'h00;
        mem[1668] = 8'h00; mem[1669] = 8'h00; mem[1670] = 8'h00; mem[1671] = 8'h00;
        mem[1672] = 8'h00; mem[1673] = 8'h00; mem[1674] = 8'h00; mem[1675] = 8'h00;
        mem[1676] = 8'h00; mem[1677] = 8'h00; mem[1678] = 8'h00; mem[1679] = 8'h00;
        mem[1680] = 8'h00; mem[1681] = 8'h00; mem[1682] = 8'h00; mem[1683] = 8'h01;
        mem[1684] = 8'h00; mem[1685] = 8'h00; mem[1686] = 8'h00; mem[1687] = 8'h01;
        mem[1688] = 8'h00; mem[1689] = 8'h00; mem[1690] = 8'h00; mem[1691] = 8'h00;
        mem[1692] = 8'h00; mem[1693] = 8'h00; mem[1694] = 8'h00; mem[1695] = 8'h00;
        mem[1696] = 8'h00; mem[1697] = 8'h00; mem[1698] = 8'h00; mem[1699] = 8'h00;
        mem[1700] = 8'h00; mem[1701] = 8'h00; mem[1702] = 8'h00; mem[1703] = 8'h00;
        mem[1704] = 8'h00; mem[1705] = 8'h00; mem[1706] = 8'h00; mem[1707] = 8'h00;
        mem[1708] = 8'h00; mem[1709] = 8'h00; mem[1710] = 8'h00; mem[1711] = 8'h00;
        mem[1712] = 8'h00; mem[1713] = 8'h00; mem[1714] = 8'h00; mem[1715] = 8'h00;
        mem[1716] = 8'h00; mem[1717] = 8'h00; mem[1718] = 8'h00; mem[1719] = 8'h00;
        mem[1720] = 8'h00; mem[1721] = 8'h00; mem[1722] = 8'h00; mem[1723] = 8'h01;
        mem[1724] = 8'h00; mem[1725] = 8'h00; mem[1726] = 8'h00; mem[1727] = 8'h01;
        mem[1728] = 8'h00; mem[1729] = 8'h00; mem[1730] = 8'h00; mem[1731] = 8'h00;
        mem[1732] = 8'h00; mem[1733] = 8'h00; mem[1734] = 8'h00; mem[1735] = 8'h00;
        mem[1736] = 8'h00; mem[1737] = 8'h00; mem[1738] = 8'h00; mem[1739] = 8'h00;
        mem[1740] = 8'h00; mem[1741] = 8'h00; mem[1742] = 8'h00; mem[1743] = 8'h00;
        mem[1744] = 8'h00; mem[1745] = 8'h00; mem[1746] = 8'h00; mem[1747] = 8'h00;
        mem[1748] = 8'h00; mem[1749] = 8'h00; mem[1750] = 8'h00; mem[1751] = 8'h00;
        mem[1752] = 8'h00; mem[1753] = 8'h00; mem[1754] = 8'h00; mem[1755] = 8'h00;
        mem[1756] = 8'h00; mem[1757] = 8'h00; mem[1758] = 8'h00; mem[1759] = 8'h00;
        mem[1760] = 8'h00; mem[1761] = 8'h00; mem[1762] = 8'h00; mem[1763] = 8'h01;
        mem[1764] = 8'h00; mem[1765] = 8'h00; mem[1766] = 8'h00; mem[1767] = 8'h01;
        mem[1768] = 8'h00; mem[1769] = 8'h00; mem[1770] = 8'h00; mem[1771] = 8'h00;
        mem[1772] = 8'h00; mem[1773] = 8'h00; mem[1774] = 8'h00; mem[1775] = 8'h00;
        mem[1776] = 8'h00; mem[1777] = 8'h00; mem[1778] = 8'h00; mem[1779] = 8'h00;
        mem[1780] = 8'h00; mem[1781] = 8'h00; mem[1782] = 8'h00; mem[1783] = 8'h00;
        mem[1784] = 8'h00; mem[1785] = 8'h00; mem[1786] = 8'h00; mem[1787] = 8'h00;
        mem[1788] = 8'h00; mem[1789] = 8'h00; mem[1790] = 8'h00; mem[1791] = 8'h00;
        mem[1792] = 8'h00; mem[1793] = 8'h00; mem[1794] = 8'h00; mem[1795] = 8'h00;
        mem[1796] = 8'h00; mem[1797] = 8'h00; mem[1798] = 8'h00; mem[1799] = 8'h00;
        mem[1800] = 8'h00; mem[1801] = 8'h00; mem[1802] = 8'h00; mem[1803] = 8'h01;
        mem[1804] = 8'h00; mem[1805] = 8'h00; mem[1806] = 8'h00; mem[1807] = 8'h01;
        mem[1808] = 8'h00; mem[1809] = 8'h00; mem[1810] = 8'h00; mem[1811] = 8'h01;
        mem[1812] = 8'h00; mem[1813] = 8'h00; mem[1814] = 8'h00; mem[1815] = 8'h01;
        mem[1816] = 8'h00; mem[1817] = 8'h00; mem[1818] = 8'h00; mem[1819] = 8'h01;
        mem[1820] = 8'h00; mem[1821] = 8'h00; mem[1822] = 8'h00; mem[1823] = 8'h01;
        mem[1824] = 8'h00; mem[1825] = 8'h00; mem[1826] = 8'h00; mem[1827] = 8'h01;
        mem[1828] = 8'h00; mem[1829] = 8'h00; mem[1830] = 8'h00; mem[1831] = 8'h01;
        mem[1832] = 8'h00; mem[1833] = 8'h00; mem[1834] = 8'h00; mem[1835] = 8'h01;
        mem[1836] = 8'h00; mem[1837] = 8'h00; mem[1838] = 8'h00; mem[1839] = 8'h01;
        mem[1840] = 8'h00; mem[1841] = 8'h00; mem[1842] = 8'h00; mem[1843] = 8'h01;
        // ---- Arena end (0x0733). Ray lengths/heights initialized to 0 by loop above. ----
    end

    // ---- combinational read ----
    always @(*) begin
        if (memRead) begin
            if (address[31:8] != 24'hFFFFFF) begin
                readData = {mem[address], mem[address+1], mem[address+2], mem[address+3]};
            end else begin
                if (address[7:0] < ioWidth)
                    readData = {32{memMappedIO[address[7:0]]}};
                else
                    readData = 32'b0;
            end
        end else begin
            readData = 32'b0;
        end
    end

    // ---- synchronous write ----
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // for (i = 0; i < memorySizeInBytes; i = i + 1)
            //     mem[i] <= 8'h00;
        end
        else begin
            if (memWrite && address[31:8] != 24'hFFFFFF) begin
                mem[address]   <= writeData[31:24];
                mem[address+1] <= writeData[23:16];
                mem[address+2] <= writeData[15:8];
                mem[address+3] <= writeData[7:0];
            end
        end
    end

endmodule