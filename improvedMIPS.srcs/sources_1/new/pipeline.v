`timescale 1ns / 1ps

// pipeline.v - updated for DDA raycaster
// Changes vs original:
//   - colHeights [4095:0] output removed (dangling wire, never driven)
//   - h0..h127 outputs added: 128 individual 32-bit wires tapping DMEM
//     column-heights region at 0x0934 + i*4 (big-endian, LSB byte = integer height)
//   - FXPU .f parameter changed from 5'd0 to 5'd8 for correct 24.8 fixed-point
//     multiply and divide (per design spec decision #1)

module pipeline #(parameter inputs = 256)(
    input  wire              clock,
    input  wire              reset,
    input  wire [inputs-1:0] memMappedIO,

    // Column heights: 128 individual 32-bit outputs tapped from DMEM
    // CHEIGHT_BASE = 0x0734 = 1844; h[i] = DMEM[1844 + i*4] (big-endian word)
    output wire [31:0] h0,   output wire [31:0] h1,   output wire [31:0] h2,
    output wire [31:0] h3,   output wire [31:0] h4,   output wire [31:0] h5,
    output wire [31:0] h6,   output wire [31:0] h7,   output wire [31:0] h8,
    output wire [31:0] h9,   output wire [31:0] h10,  output wire [31:0] h11,
    output wire [31:0] h12,  output wire [31:0] h13,  output wire [31:0] h14,
    output wire [31:0] h15,  output wire [31:0] h16,  output wire [31:0] h17,
    output wire [31:0] h18,  output wire [31:0] h19,  output wire [31:0] h20,
    output wire [31:0] h21,  output wire [31:0] h22,  output wire [31:0] h23,
    output wire [31:0] h24,  output wire [31:0] h25,  output wire [31:0] h26,
    output wire [31:0] h27,  output wire [31:0] h28,  output wire [31:0] h29,
    output wire [31:0] h30,  output wire [31:0] h31,  output wire [31:0] h32,
    output wire [31:0] h33,  output wire [31:0] h34,  output wire [31:0] h35,
    output wire [31:0] h36,  output wire [31:0] h37,  output wire [31:0] h38,
    output wire [31:0] h39,  output wire [31:0] h40,  output wire [31:0] h41,
    output wire [31:0] h42,  output wire [31:0] h43,  output wire [31:0] h44,
    output wire [31:0] h45,  output wire [31:0] h46,  output wire [31:0] h47,
    output wire [31:0] h48,  output wire [31:0] h49,  output wire [31:0] h50,
    output wire [31:0] h51,  output wire [31:0] h52,  output wire [31:0] h53,
    output wire [31:0] h54,  output wire [31:0] h55,  output wire [31:0] h56,
    output wire [31:0] h57,  output wire [31:0] h58,  output wire [31:0] h59,
    output wire [31:0] h60,  output wire [31:0] h61,  output wire [31:0] h62,
    output wire [31:0] h63,  output wire [31:0] h64,  output wire [31:0] h65,
    output wire [31:0] h66,  output wire [31:0] h67,  output wire [31:0] h68,
    output wire [31:0] h69,  output wire [31:0] h70,  output wire [31:0] h71,
    output wire [31:0] h72,  output wire [31:0] h73,  output wire [31:0] h74,
    output wire [31:0] h75,  output wire [31:0] h76,  output wire [31:0] h77,
    output wire [31:0] h78,  output wire [31:0] h79,  output wire [31:0] h80,
    output wire [31:0] h81,  output wire [31:0] h82,  output wire [31:0] h83,
    output wire [31:0] h84,  output wire [31:0] h85,  output wire [31:0] h86,
    output wire [31:0] h87,  output wire [31:0] h88,  output wire [31:0] h89,
    output wire [31:0] h90,  output wire [31:0] h91,  output wire [31:0] h92,
    output wire [31:0] h93,  output wire [31:0] h94,  output wire [31:0] h95,
    output wire [31:0] h96,  output wire [31:0] h97,  output wire [31:0] h98,
    output wire [31:0] h99,  output wire [31:0] h100, output wire [31:0] h101,
    output wire [31:0] h102, output wire [31:0] h103, output wire [31:0] h104,
    output wire [31:0] h105, output wire [31:0] h106, output wire [31:0] h107,
    output wire [31:0] h108, output wire [31:0] h109, output wire [31:0] h110,
    output wire [31:0] h111, output wire [31:0] h112, output wire [31:0] h113,
    output wire [31:0] h114, output wire [31:0] h115, output wire [31:0] h116,
    output wire [31:0] h117, output wire [31:0] h118, output wire [31:0] h119,
    output wire [31:0] h120, output wire [31:0] h121, output wire [31:0] h122,
    output wire [31:0] h123, output wire [31:0] h124, output wire [31:0] h125,
    output wire [31:0] h126, output wire [31:0] h127,

    output wire [31:0] r1,
    output wire [31:0] r2
);

    // =====================================================================
    // DMEM column-heights tap
    // CHEIGHT_BASE = 1844 = 0x0734. Each entry = 4 bytes, big-endian.
    // Big-endian word: mem[base], mem[base+1], mem[base+2], mem[base+3]
    // The integer height is a small positive number stored in the LSB.
    // =====================================================================
    localparam CHEIGHT_BASE = 32'd1844;

    // These are combinational reads directly from the DMEM flip-flop array.
    // The 'mem' array inside memory.v is a reg, so hierarchical references
    // are valid for simulation. For synthesis the renderer would need a
    // dedicated read port; this tap is simulation-correct and synthesis-ready
    // if DMEM is implemented as a dual-port BRAM.
    assign h0   = {DMEM.mem[CHEIGHT_BASE +   0], DMEM.mem[CHEIGHT_BASE +   1], DMEM.mem[CHEIGHT_BASE +   2], DMEM.mem[CHEIGHT_BASE +   3]};
    assign h1   = {DMEM.mem[CHEIGHT_BASE +   4], DMEM.mem[CHEIGHT_BASE +   5], DMEM.mem[CHEIGHT_BASE +   6], DMEM.mem[CHEIGHT_BASE +   7]};
    assign h2   = {DMEM.mem[CHEIGHT_BASE +   8], DMEM.mem[CHEIGHT_BASE +   9], DMEM.mem[CHEIGHT_BASE +  10], DMEM.mem[CHEIGHT_BASE +  11]};
    assign h3   = {DMEM.mem[CHEIGHT_BASE +  12], DMEM.mem[CHEIGHT_BASE +  13], DMEM.mem[CHEIGHT_BASE +  14], DMEM.mem[CHEIGHT_BASE +  15]};
    assign h4   = {DMEM.mem[CHEIGHT_BASE +  16], DMEM.mem[CHEIGHT_BASE +  17], DMEM.mem[CHEIGHT_BASE +  18], DMEM.mem[CHEIGHT_BASE +  19]};
    assign h5   = {DMEM.mem[CHEIGHT_BASE +  20], DMEM.mem[CHEIGHT_BASE +  21], DMEM.mem[CHEIGHT_BASE +  22], DMEM.mem[CHEIGHT_BASE +  23]};
    assign h6   = {DMEM.mem[CHEIGHT_BASE +  24], DMEM.mem[CHEIGHT_BASE +  25], DMEM.mem[CHEIGHT_BASE +  26], DMEM.mem[CHEIGHT_BASE +  27]};
    assign h7   = {DMEM.mem[CHEIGHT_BASE +  28], DMEM.mem[CHEIGHT_BASE +  29], DMEM.mem[CHEIGHT_BASE +  30], DMEM.mem[CHEIGHT_BASE +  31]};
    assign h8   = {DMEM.mem[CHEIGHT_BASE +  32], DMEM.mem[CHEIGHT_BASE +  33], DMEM.mem[CHEIGHT_BASE +  34], DMEM.mem[CHEIGHT_BASE +  35]};
    assign h9   = {DMEM.mem[CHEIGHT_BASE +  36], DMEM.mem[CHEIGHT_BASE +  37], DMEM.mem[CHEIGHT_BASE +  38], DMEM.mem[CHEIGHT_BASE +  39]};
    assign h10  = {DMEM.mem[CHEIGHT_BASE +  40], DMEM.mem[CHEIGHT_BASE +  41], DMEM.mem[CHEIGHT_BASE +  42], DMEM.mem[CHEIGHT_BASE +  43]};
    assign h11  = {DMEM.mem[CHEIGHT_BASE +  44], DMEM.mem[CHEIGHT_BASE +  45], DMEM.mem[CHEIGHT_BASE +  46], DMEM.mem[CHEIGHT_BASE +  47]};
    assign h12  = {DMEM.mem[CHEIGHT_BASE +  48], DMEM.mem[CHEIGHT_BASE +  49], DMEM.mem[CHEIGHT_BASE +  50], DMEM.mem[CHEIGHT_BASE +  51]};
    assign h13  = {DMEM.mem[CHEIGHT_BASE +  52], DMEM.mem[CHEIGHT_BASE +  53], DMEM.mem[CHEIGHT_BASE +  54], DMEM.mem[CHEIGHT_BASE +  55]};
    assign h14  = {DMEM.mem[CHEIGHT_BASE +  56], DMEM.mem[CHEIGHT_BASE +  57], DMEM.mem[CHEIGHT_BASE +  58], DMEM.mem[CHEIGHT_BASE +  59]};
    assign h15  = {DMEM.mem[CHEIGHT_BASE +  60], DMEM.mem[CHEIGHT_BASE +  61], DMEM.mem[CHEIGHT_BASE +  62], DMEM.mem[CHEIGHT_BASE +  63]};
    assign h16  = {DMEM.mem[CHEIGHT_BASE +  64], DMEM.mem[CHEIGHT_BASE +  65], DMEM.mem[CHEIGHT_BASE +  66], DMEM.mem[CHEIGHT_BASE +  67]};
    assign h17  = {DMEM.mem[CHEIGHT_BASE +  68], DMEM.mem[CHEIGHT_BASE +  69], DMEM.mem[CHEIGHT_BASE +  70], DMEM.mem[CHEIGHT_BASE +  71]};
    assign h18  = {DMEM.mem[CHEIGHT_BASE +  72], DMEM.mem[CHEIGHT_BASE +  73], DMEM.mem[CHEIGHT_BASE +  74], DMEM.mem[CHEIGHT_BASE +  75]};
    assign h19  = {DMEM.mem[CHEIGHT_BASE +  76], DMEM.mem[CHEIGHT_BASE +  77], DMEM.mem[CHEIGHT_BASE +  78], DMEM.mem[CHEIGHT_BASE +  79]};
    assign h20  = {DMEM.mem[CHEIGHT_BASE +  80], DMEM.mem[CHEIGHT_BASE +  81], DMEM.mem[CHEIGHT_BASE +  82], DMEM.mem[CHEIGHT_BASE +  83]};
    assign h21  = {DMEM.mem[CHEIGHT_BASE +  84], DMEM.mem[CHEIGHT_BASE +  85], DMEM.mem[CHEIGHT_BASE +  86], DMEM.mem[CHEIGHT_BASE +  87]};
    assign h22  = {DMEM.mem[CHEIGHT_BASE +  88], DMEM.mem[CHEIGHT_BASE +  89], DMEM.mem[CHEIGHT_BASE +  90], DMEM.mem[CHEIGHT_BASE +  91]};
    assign h23  = {DMEM.mem[CHEIGHT_BASE +  92], DMEM.mem[CHEIGHT_BASE +  93], DMEM.mem[CHEIGHT_BASE +  94], DMEM.mem[CHEIGHT_BASE +  95]};
    assign h24  = {DMEM.mem[CHEIGHT_BASE +  96], DMEM.mem[CHEIGHT_BASE +  97], DMEM.mem[CHEIGHT_BASE +  98], DMEM.mem[CHEIGHT_BASE +  99]};
    assign h25  = {DMEM.mem[CHEIGHT_BASE + 100], DMEM.mem[CHEIGHT_BASE + 101], DMEM.mem[CHEIGHT_BASE + 102], DMEM.mem[CHEIGHT_BASE + 103]};
    assign h26  = {DMEM.mem[CHEIGHT_BASE + 104], DMEM.mem[CHEIGHT_BASE + 105], DMEM.mem[CHEIGHT_BASE + 106], DMEM.mem[CHEIGHT_BASE + 107]};
    assign h27  = {DMEM.mem[CHEIGHT_BASE + 108], DMEM.mem[CHEIGHT_BASE + 109], DMEM.mem[CHEIGHT_BASE + 110], DMEM.mem[CHEIGHT_BASE + 111]};
    assign h28  = {DMEM.mem[CHEIGHT_BASE + 112], DMEM.mem[CHEIGHT_BASE + 113], DMEM.mem[CHEIGHT_BASE + 114], DMEM.mem[CHEIGHT_BASE + 115]};
    assign h29  = {DMEM.mem[CHEIGHT_BASE + 116], DMEM.mem[CHEIGHT_BASE + 117], DMEM.mem[CHEIGHT_BASE + 118], DMEM.mem[CHEIGHT_BASE + 119]};
    assign h30  = {DMEM.mem[CHEIGHT_BASE + 120], DMEM.mem[CHEIGHT_BASE + 121], DMEM.mem[CHEIGHT_BASE + 122], DMEM.mem[CHEIGHT_BASE + 123]};
    assign h31  = {DMEM.mem[CHEIGHT_BASE + 124], DMEM.mem[CHEIGHT_BASE + 125], DMEM.mem[CHEIGHT_BASE + 126], DMEM.mem[CHEIGHT_BASE + 127]};
    assign h32  = {DMEM.mem[CHEIGHT_BASE + 128], DMEM.mem[CHEIGHT_BASE + 129], DMEM.mem[CHEIGHT_BASE + 130], DMEM.mem[CHEIGHT_BASE + 131]};
    assign h33  = {DMEM.mem[CHEIGHT_BASE + 132], DMEM.mem[CHEIGHT_BASE + 133], DMEM.mem[CHEIGHT_BASE + 134], DMEM.mem[CHEIGHT_BASE + 135]};
    assign h34  = {DMEM.mem[CHEIGHT_BASE + 136], DMEM.mem[CHEIGHT_BASE + 137], DMEM.mem[CHEIGHT_BASE + 138], DMEM.mem[CHEIGHT_BASE + 139]};
    assign h35  = {DMEM.mem[CHEIGHT_BASE + 140], DMEM.mem[CHEIGHT_BASE + 141], DMEM.mem[CHEIGHT_BASE + 142], DMEM.mem[CHEIGHT_BASE + 143]};
    assign h36  = {DMEM.mem[CHEIGHT_BASE + 144], DMEM.mem[CHEIGHT_BASE + 145], DMEM.mem[CHEIGHT_BASE + 146], DMEM.mem[CHEIGHT_BASE + 147]};
    assign h37  = {DMEM.mem[CHEIGHT_BASE + 148], DMEM.mem[CHEIGHT_BASE + 149], DMEM.mem[CHEIGHT_BASE + 150], DMEM.mem[CHEIGHT_BASE + 151]};
    assign h38  = {DMEM.mem[CHEIGHT_BASE + 152], DMEM.mem[CHEIGHT_BASE + 153], DMEM.mem[CHEIGHT_BASE + 154], DMEM.mem[CHEIGHT_BASE + 155]};
    assign h39  = {DMEM.mem[CHEIGHT_BASE + 156], DMEM.mem[CHEIGHT_BASE + 157], DMEM.mem[CHEIGHT_BASE + 158], DMEM.mem[CHEIGHT_BASE + 159]};
    assign h40  = {DMEM.mem[CHEIGHT_BASE + 160], DMEM.mem[CHEIGHT_BASE + 161], DMEM.mem[CHEIGHT_BASE + 162], DMEM.mem[CHEIGHT_BASE + 163]};
    assign h41  = {DMEM.mem[CHEIGHT_BASE + 164], DMEM.mem[CHEIGHT_BASE + 165], DMEM.mem[CHEIGHT_BASE + 166], DMEM.mem[CHEIGHT_BASE + 167]};
    assign h42  = {DMEM.mem[CHEIGHT_BASE + 168], DMEM.mem[CHEIGHT_BASE + 169], DMEM.mem[CHEIGHT_BASE + 170], DMEM.mem[CHEIGHT_BASE + 171]};
    assign h43  = {DMEM.mem[CHEIGHT_BASE + 172], DMEM.mem[CHEIGHT_BASE + 173], DMEM.mem[CHEIGHT_BASE + 174], DMEM.mem[CHEIGHT_BASE + 175]};
    assign h44  = {DMEM.mem[CHEIGHT_BASE + 176], DMEM.mem[CHEIGHT_BASE + 177], DMEM.mem[CHEIGHT_BASE + 178], DMEM.mem[CHEIGHT_BASE + 179]};
    assign h45  = {DMEM.mem[CHEIGHT_BASE + 180], DMEM.mem[CHEIGHT_BASE + 181], DMEM.mem[CHEIGHT_BASE + 182], DMEM.mem[CHEIGHT_BASE + 183]};
    assign h46  = {DMEM.mem[CHEIGHT_BASE + 184], DMEM.mem[CHEIGHT_BASE + 185], DMEM.mem[CHEIGHT_BASE + 186], DMEM.mem[CHEIGHT_BASE + 187]};
    assign h47  = {DMEM.mem[CHEIGHT_BASE + 188], DMEM.mem[CHEIGHT_BASE + 189], DMEM.mem[CHEIGHT_BASE + 190], DMEM.mem[CHEIGHT_BASE + 191]};
    assign h48  = {DMEM.mem[CHEIGHT_BASE + 192], DMEM.mem[CHEIGHT_BASE + 193], DMEM.mem[CHEIGHT_BASE + 194], DMEM.mem[CHEIGHT_BASE + 195]};
    assign h49  = {DMEM.mem[CHEIGHT_BASE + 196], DMEM.mem[CHEIGHT_BASE + 197], DMEM.mem[CHEIGHT_BASE + 198], DMEM.mem[CHEIGHT_BASE + 199]};
    assign h50  = {DMEM.mem[CHEIGHT_BASE + 200], DMEM.mem[CHEIGHT_BASE + 201], DMEM.mem[CHEIGHT_BASE + 202], DMEM.mem[CHEIGHT_BASE + 203]};
    assign h51  = {DMEM.mem[CHEIGHT_BASE + 204], DMEM.mem[CHEIGHT_BASE + 205], DMEM.mem[CHEIGHT_BASE + 206], DMEM.mem[CHEIGHT_BASE + 207]};
    assign h52  = {DMEM.mem[CHEIGHT_BASE + 208], DMEM.mem[CHEIGHT_BASE + 209], DMEM.mem[CHEIGHT_BASE + 210], DMEM.mem[CHEIGHT_BASE + 211]};
    assign h53  = {DMEM.mem[CHEIGHT_BASE + 212], DMEM.mem[CHEIGHT_BASE + 213], DMEM.mem[CHEIGHT_BASE + 214], DMEM.mem[CHEIGHT_BASE + 215]};
    assign h54  = {DMEM.mem[CHEIGHT_BASE + 216], DMEM.mem[CHEIGHT_BASE + 217], DMEM.mem[CHEIGHT_BASE + 218], DMEM.mem[CHEIGHT_BASE + 219]};
    assign h55  = {DMEM.mem[CHEIGHT_BASE + 220], DMEM.mem[CHEIGHT_BASE + 221], DMEM.mem[CHEIGHT_BASE + 222], DMEM.mem[CHEIGHT_BASE + 223]};
    assign h56  = {DMEM.mem[CHEIGHT_BASE + 224], DMEM.mem[CHEIGHT_BASE + 225], DMEM.mem[CHEIGHT_BASE + 226], DMEM.mem[CHEIGHT_BASE + 227]};
    assign h57  = {DMEM.mem[CHEIGHT_BASE + 228], DMEM.mem[CHEIGHT_BASE + 229], DMEM.mem[CHEIGHT_BASE + 230], DMEM.mem[CHEIGHT_BASE + 231]};
    assign h58  = {DMEM.mem[CHEIGHT_BASE + 232], DMEM.mem[CHEIGHT_BASE + 233], DMEM.mem[CHEIGHT_BASE + 234], DMEM.mem[CHEIGHT_BASE + 235]};
    assign h59  = {DMEM.mem[CHEIGHT_BASE + 236], DMEM.mem[CHEIGHT_BASE + 237], DMEM.mem[CHEIGHT_BASE + 238], DMEM.mem[CHEIGHT_BASE + 239]};
    assign h60  = {DMEM.mem[CHEIGHT_BASE + 240], DMEM.mem[CHEIGHT_BASE + 241], DMEM.mem[CHEIGHT_BASE + 242], DMEM.mem[CHEIGHT_BASE + 243]};
    assign h61  = {DMEM.mem[CHEIGHT_BASE + 244], DMEM.mem[CHEIGHT_BASE + 245], DMEM.mem[CHEIGHT_BASE + 246], DMEM.mem[CHEIGHT_BASE + 247]};
    assign h62  = {DMEM.mem[CHEIGHT_BASE + 248], DMEM.mem[CHEIGHT_BASE + 249], DMEM.mem[CHEIGHT_BASE + 250], DMEM.mem[CHEIGHT_BASE + 251]};
    assign h63  = {DMEM.mem[CHEIGHT_BASE + 252], DMEM.mem[CHEIGHT_BASE + 253], DMEM.mem[CHEIGHT_BASE + 254], DMEM.mem[CHEIGHT_BASE + 255]};
    assign h64  = {DMEM.mem[CHEIGHT_BASE + 256], DMEM.mem[CHEIGHT_BASE + 257], DMEM.mem[CHEIGHT_BASE + 258], DMEM.mem[CHEIGHT_BASE + 259]};
    assign h65  = {DMEM.mem[CHEIGHT_BASE + 260], DMEM.mem[CHEIGHT_BASE + 261], DMEM.mem[CHEIGHT_BASE + 262], DMEM.mem[CHEIGHT_BASE + 263]};
    assign h66  = {DMEM.mem[CHEIGHT_BASE + 264], DMEM.mem[CHEIGHT_BASE + 265], DMEM.mem[CHEIGHT_BASE + 266], DMEM.mem[CHEIGHT_BASE + 267]};
    assign h67  = {DMEM.mem[CHEIGHT_BASE + 268], DMEM.mem[CHEIGHT_BASE + 269], DMEM.mem[CHEIGHT_BASE + 270], DMEM.mem[CHEIGHT_BASE + 271]};
    assign h68  = {DMEM.mem[CHEIGHT_BASE + 272], DMEM.mem[CHEIGHT_BASE + 273], DMEM.mem[CHEIGHT_BASE + 274], DMEM.mem[CHEIGHT_BASE + 275]};
    assign h69  = {DMEM.mem[CHEIGHT_BASE + 276], DMEM.mem[CHEIGHT_BASE + 277], DMEM.mem[CHEIGHT_BASE + 278], DMEM.mem[CHEIGHT_BASE + 279]};
    assign h70  = {DMEM.mem[CHEIGHT_BASE + 280], DMEM.mem[CHEIGHT_BASE + 281], DMEM.mem[CHEIGHT_BASE + 282], DMEM.mem[CHEIGHT_BASE + 283]};
    assign h71  = {DMEM.mem[CHEIGHT_BASE + 284], DMEM.mem[CHEIGHT_BASE + 285], DMEM.mem[CHEIGHT_BASE + 286], DMEM.mem[CHEIGHT_BASE + 287]};
    assign h72  = {DMEM.mem[CHEIGHT_BASE + 288], DMEM.mem[CHEIGHT_BASE + 289], DMEM.mem[CHEIGHT_BASE + 290], DMEM.mem[CHEIGHT_BASE + 291]};
    assign h73  = {DMEM.mem[CHEIGHT_BASE + 292], DMEM.mem[CHEIGHT_BASE + 293], DMEM.mem[CHEIGHT_BASE + 294], DMEM.mem[CHEIGHT_BASE + 295]};
    assign h74  = {DMEM.mem[CHEIGHT_BASE + 296], DMEM.mem[CHEIGHT_BASE + 297], DMEM.mem[CHEIGHT_BASE + 298], DMEM.mem[CHEIGHT_BASE + 299]};
    assign h75  = {DMEM.mem[CHEIGHT_BASE + 300], DMEM.mem[CHEIGHT_BASE + 301], DMEM.mem[CHEIGHT_BASE + 302], DMEM.mem[CHEIGHT_BASE + 303]};
    assign h76  = {DMEM.mem[CHEIGHT_BASE + 304], DMEM.mem[CHEIGHT_BASE + 305], DMEM.mem[CHEIGHT_BASE + 306], DMEM.mem[CHEIGHT_BASE + 307]};
    assign h77  = {DMEM.mem[CHEIGHT_BASE + 308], DMEM.mem[CHEIGHT_BASE + 309], DMEM.mem[CHEIGHT_BASE + 310], DMEM.mem[CHEIGHT_BASE + 311]};
    assign h78  = {DMEM.mem[CHEIGHT_BASE + 312], DMEM.mem[CHEIGHT_BASE + 313], DMEM.mem[CHEIGHT_BASE + 314], DMEM.mem[CHEIGHT_BASE + 315]};
    assign h79  = {DMEM.mem[CHEIGHT_BASE + 316], DMEM.mem[CHEIGHT_BASE + 317], DMEM.mem[CHEIGHT_BASE + 318], DMEM.mem[CHEIGHT_BASE + 319]};
    assign h80  = {DMEM.mem[CHEIGHT_BASE + 320], DMEM.mem[CHEIGHT_BASE + 321], DMEM.mem[CHEIGHT_BASE + 322], DMEM.mem[CHEIGHT_BASE + 323]};
    assign h81  = {DMEM.mem[CHEIGHT_BASE + 324], DMEM.mem[CHEIGHT_BASE + 325], DMEM.mem[CHEIGHT_BASE + 326], DMEM.mem[CHEIGHT_BASE + 327]};
    assign h82  = {DMEM.mem[CHEIGHT_BASE + 328], DMEM.mem[CHEIGHT_BASE + 329], DMEM.mem[CHEIGHT_BASE + 330], DMEM.mem[CHEIGHT_BASE + 331]};
    assign h83  = {DMEM.mem[CHEIGHT_BASE + 332], DMEM.mem[CHEIGHT_BASE + 333], DMEM.mem[CHEIGHT_BASE + 334], DMEM.mem[CHEIGHT_BASE + 335]};
    assign h84  = {DMEM.mem[CHEIGHT_BASE + 336], DMEM.mem[CHEIGHT_BASE + 337], DMEM.mem[CHEIGHT_BASE + 338], DMEM.mem[CHEIGHT_BASE + 339]};
    assign h85  = {DMEM.mem[CHEIGHT_BASE + 340], DMEM.mem[CHEIGHT_BASE + 341], DMEM.mem[CHEIGHT_BASE + 342], DMEM.mem[CHEIGHT_BASE + 343]};
    assign h86  = {DMEM.mem[CHEIGHT_BASE + 344], DMEM.mem[CHEIGHT_BASE + 345], DMEM.mem[CHEIGHT_BASE + 346], DMEM.mem[CHEIGHT_BASE + 347]};
    assign h87  = {DMEM.mem[CHEIGHT_BASE + 348], DMEM.mem[CHEIGHT_BASE + 349], DMEM.mem[CHEIGHT_BASE + 350], DMEM.mem[CHEIGHT_BASE + 351]};
    assign h88  = {DMEM.mem[CHEIGHT_BASE + 352], DMEM.mem[CHEIGHT_BASE + 353], DMEM.mem[CHEIGHT_BASE + 354], DMEM.mem[CHEIGHT_BASE + 355]};
    assign h89  = {DMEM.mem[CHEIGHT_BASE + 356], DMEM.mem[CHEIGHT_BASE + 357], DMEM.mem[CHEIGHT_BASE + 358], DMEM.mem[CHEIGHT_BASE + 359]};
    assign h90  = {DMEM.mem[CHEIGHT_BASE + 360], DMEM.mem[CHEIGHT_BASE + 361], DMEM.mem[CHEIGHT_BASE + 362], DMEM.mem[CHEIGHT_BASE + 363]};
    assign h91  = {DMEM.mem[CHEIGHT_BASE + 364], DMEM.mem[CHEIGHT_BASE + 365], DMEM.mem[CHEIGHT_BASE + 366], DMEM.mem[CHEIGHT_BASE + 367]};
    assign h92  = {DMEM.mem[CHEIGHT_BASE + 368], DMEM.mem[CHEIGHT_BASE + 369], DMEM.mem[CHEIGHT_BASE + 370], DMEM.mem[CHEIGHT_BASE + 371]};
    assign h93  = {DMEM.mem[CHEIGHT_BASE + 372], DMEM.mem[CHEIGHT_BASE + 373], DMEM.mem[CHEIGHT_BASE + 374], DMEM.mem[CHEIGHT_BASE + 375]};
    assign h94  = {DMEM.mem[CHEIGHT_BASE + 376], DMEM.mem[CHEIGHT_BASE + 377], DMEM.mem[CHEIGHT_BASE + 378], DMEM.mem[CHEIGHT_BASE + 379]};
    assign h95  = {DMEM.mem[CHEIGHT_BASE + 380], DMEM.mem[CHEIGHT_BASE + 381], DMEM.mem[CHEIGHT_BASE + 382], DMEM.mem[CHEIGHT_BASE + 383]};
    assign h96  = {DMEM.mem[CHEIGHT_BASE + 384], DMEM.mem[CHEIGHT_BASE + 385], DMEM.mem[CHEIGHT_BASE + 386], DMEM.mem[CHEIGHT_BASE + 387]};
    assign h97  = {DMEM.mem[CHEIGHT_BASE + 388], DMEM.mem[CHEIGHT_BASE + 389], DMEM.mem[CHEIGHT_BASE + 390], DMEM.mem[CHEIGHT_BASE + 391]};
    assign h98  = {DMEM.mem[CHEIGHT_BASE + 392], DMEM.mem[CHEIGHT_BASE + 393], DMEM.mem[CHEIGHT_BASE + 394], DMEM.mem[CHEIGHT_BASE + 395]};
    assign h99  = {DMEM.mem[CHEIGHT_BASE + 396], DMEM.mem[CHEIGHT_BASE + 397], DMEM.mem[CHEIGHT_BASE + 398], DMEM.mem[CHEIGHT_BASE + 399]};
    assign h100 = {DMEM.mem[CHEIGHT_BASE + 400], DMEM.mem[CHEIGHT_BASE + 401], DMEM.mem[CHEIGHT_BASE + 402], DMEM.mem[CHEIGHT_BASE + 403]};
    assign h101 = {DMEM.mem[CHEIGHT_BASE + 404], DMEM.mem[CHEIGHT_BASE + 405], DMEM.mem[CHEIGHT_BASE + 406], DMEM.mem[CHEIGHT_BASE + 407]};
    assign h102 = {DMEM.mem[CHEIGHT_BASE + 408], DMEM.mem[CHEIGHT_BASE + 409], DMEM.mem[CHEIGHT_BASE + 410], DMEM.mem[CHEIGHT_BASE + 411]};
    assign h103 = {DMEM.mem[CHEIGHT_BASE + 412], DMEM.mem[CHEIGHT_BASE + 413], DMEM.mem[CHEIGHT_BASE + 414], DMEM.mem[CHEIGHT_BASE + 415]};
    assign h104 = {DMEM.mem[CHEIGHT_BASE + 416], DMEM.mem[CHEIGHT_BASE + 417], DMEM.mem[CHEIGHT_BASE + 418], DMEM.mem[CHEIGHT_BASE + 419]};
    assign h105 = {DMEM.mem[CHEIGHT_BASE + 420], DMEM.mem[CHEIGHT_BASE + 421], DMEM.mem[CHEIGHT_BASE + 422], DMEM.mem[CHEIGHT_BASE + 423]};
    assign h106 = {DMEM.mem[CHEIGHT_BASE + 424], DMEM.mem[CHEIGHT_BASE + 425], DMEM.mem[CHEIGHT_BASE + 426], DMEM.mem[CHEIGHT_BASE + 427]};
    assign h107 = {DMEM.mem[CHEIGHT_BASE + 428], DMEM.mem[CHEIGHT_BASE + 429], DMEM.mem[CHEIGHT_BASE + 430], DMEM.mem[CHEIGHT_BASE + 431]};
    assign h108 = {DMEM.mem[CHEIGHT_BASE + 432], DMEM.mem[CHEIGHT_BASE + 433], DMEM.mem[CHEIGHT_BASE + 434], DMEM.mem[CHEIGHT_BASE + 435]};
    assign h109 = {DMEM.mem[CHEIGHT_BASE + 436], DMEM.mem[CHEIGHT_BASE + 437], DMEM.mem[CHEIGHT_BASE + 438], DMEM.mem[CHEIGHT_BASE + 439]};
    assign h110 = {DMEM.mem[CHEIGHT_BASE + 440], DMEM.mem[CHEIGHT_BASE + 441], DMEM.mem[CHEIGHT_BASE + 442], DMEM.mem[CHEIGHT_BASE + 443]};
    assign h111 = {DMEM.mem[CHEIGHT_BASE + 444], DMEM.mem[CHEIGHT_BASE + 445], DMEM.mem[CHEIGHT_BASE + 446], DMEM.mem[CHEIGHT_BASE + 447]};
    assign h112 = {DMEM.mem[CHEIGHT_BASE + 448], DMEM.mem[CHEIGHT_BASE + 449], DMEM.mem[CHEIGHT_BASE + 450], DMEM.mem[CHEIGHT_BASE + 451]};
    assign h113 = {DMEM.mem[CHEIGHT_BASE + 452], DMEM.mem[CHEIGHT_BASE + 453], DMEM.mem[CHEIGHT_BASE + 454], DMEM.mem[CHEIGHT_BASE + 455]};
    assign h114 = {DMEM.mem[CHEIGHT_BASE + 456], DMEM.mem[CHEIGHT_BASE + 457], DMEM.mem[CHEIGHT_BASE + 458], DMEM.mem[CHEIGHT_BASE + 459]};
    assign h115 = {DMEM.mem[CHEIGHT_BASE + 460], DMEM.mem[CHEIGHT_BASE + 461], DMEM.mem[CHEIGHT_BASE + 462], DMEM.mem[CHEIGHT_BASE + 463]};
    assign h116 = {DMEM.mem[CHEIGHT_BASE + 464], DMEM.mem[CHEIGHT_BASE + 465], DMEM.mem[CHEIGHT_BASE + 466], DMEM.mem[CHEIGHT_BASE + 467]};
    assign h117 = {DMEM.mem[CHEIGHT_BASE + 468], DMEM.mem[CHEIGHT_BASE + 469], DMEM.mem[CHEIGHT_BASE + 470], DMEM.mem[CHEIGHT_BASE + 471]};
    assign h118 = {DMEM.mem[CHEIGHT_BASE + 472], DMEM.mem[CHEIGHT_BASE + 473], DMEM.mem[CHEIGHT_BASE + 474], DMEM.mem[CHEIGHT_BASE + 475]};
    assign h119 = {DMEM.mem[CHEIGHT_BASE + 476], DMEM.mem[CHEIGHT_BASE + 477], DMEM.mem[CHEIGHT_BASE + 478], DMEM.mem[CHEIGHT_BASE + 479]};
    assign h120 = {DMEM.mem[CHEIGHT_BASE + 480], DMEM.mem[CHEIGHT_BASE + 481], DMEM.mem[CHEIGHT_BASE + 482], DMEM.mem[CHEIGHT_BASE + 483]};
    assign h121 = {DMEM.mem[CHEIGHT_BASE + 484], DMEM.mem[CHEIGHT_BASE + 485], DMEM.mem[CHEIGHT_BASE + 486], DMEM.mem[CHEIGHT_BASE + 487]};
    assign h122 = {DMEM.mem[CHEIGHT_BASE + 488], DMEM.mem[CHEIGHT_BASE + 489], DMEM.mem[CHEIGHT_BASE + 490], DMEM.mem[CHEIGHT_BASE + 491]};
    assign h123 = {DMEM.mem[CHEIGHT_BASE + 492], DMEM.mem[CHEIGHT_BASE + 493], DMEM.mem[CHEIGHT_BASE + 494], DMEM.mem[CHEIGHT_BASE + 495]};
    assign h124 = {DMEM.mem[CHEIGHT_BASE + 496], DMEM.mem[CHEIGHT_BASE + 497], DMEM.mem[CHEIGHT_BASE + 498], DMEM.mem[CHEIGHT_BASE + 499]};
    assign h125 = {DMEM.mem[CHEIGHT_BASE + 500], DMEM.mem[CHEIGHT_BASE + 501], DMEM.mem[CHEIGHT_BASE + 502], DMEM.mem[CHEIGHT_BASE + 503]};
    assign h126 = {DMEM.mem[CHEIGHT_BASE + 504], DMEM.mem[CHEIGHT_BASE + 505], DMEM.mem[CHEIGHT_BASE + 506], DMEM.mem[CHEIGHT_BASE + 507]};
    assign h127 = {DMEM.mem[CHEIGHT_BASE + 508], DMEM.mem[CHEIGHT_BASE + 509], DMEM.mem[CHEIGHT_BASE + 510], DMEM.mem[CHEIGHT_BASE + 511]};

    // =====================================================================
    // Pipeline internals - identical to original except:
    //   - colHeights output removed
    //   - FXPU .f(5'd8) instead of .f(5'd0)
    // =====================================================================

    wire [31:0] pc_out, pc_plus4, pc_next, if_instruction;
    wire [31:0] if_id_NPC, if_id_IR;

    wire [5:0]  id_opcode = if_id_IR[31:26];
    wire [4:0]  id_RS     = if_id_IR[25:21];
    wire [4:0]  id_RT     = if_id_IR[20:16];
    wire [4:0]  id_RD     = if_id_IR[15:11];
    wire [5:0]  id_funct  = if_id_IR[5:0];
    wire [15:0] id_imm16  = if_id_IR[15:0];

    wire        id_regDst, id_aluSrc, id_memToReg;
    wire        id_regWrite, id_memRead, id_memWrite;
    wire        id_branchEq, id_branchNe, id_jump, id_jal, id_jr;
    wire [3:0]  id_aluOp;
    wire        hdu_PCWrite, hdu_IF_IDWrite, hdu_ID_EXStall;
    wire        mem_PCSrc;
    wire        fxpu_stall_all;
    wire        fxpu_stall_id;

    wire id_isMul = (id_opcode == 6'b000000) && (id_funct == 6'b011000);
    wire id_isDiv = (id_opcode == 6'b000000) && (id_funct == 6'b011010);

    pc PC (
        .clock(clock), .reset(reset),
        .pcStall(~hdu_PCWrite | fxpu_stall_id),
        .pcInVal(pc_next), .pcOutVal(pc_out)
    );
    adder PC_ADDER (.a(pc_out), .b(32'd4), .sum(pc_plus4));
    instructionMem IMEM (.pcVal(pc_out), .instruction(if_instruction), .reset(reset));

    if_id IF_ID (
        .clock(clock), .reset(reset),
        .if_id_stall(~hdu_IF_IDWrite | fxpu_stall_id),
        .if_id_flush(id_jump | id_jal | id_jr | mem_PCSrc),
        .if_id_NPC_in(pc_plus4),   .if_id_IR_in(if_instruction),
        .if_id_NPC_out(if_id_NPC), .if_id_IR_out(if_id_IR)
    );

    wire [31:0] jumpAddress, branchMuxOut, jumpMuxOut;
    jTypeAddressProcessor JUMP_ADDR_PROC (
        .if_id_IR(if_id_IR), .if_id_NPC(if_id_NPC), .jumpAddress(jumpAddress)
    );
    mux2 #(.width(32)) JUMP_MUX (
        .in0(branchMuxOut), .in1(jumpAddress), .s(id_jump | id_jal), .out(jumpMuxOut)
    );

    wire [31:0] id_rd1, id_rd2;
    mux2 #(.width(32)) JR_MUX (
        .in0(jumpMuxOut), .in1(id_rd1), .s(id_jr), .out(pc_next)
    );

    mainControl CTRL (
        .opCode(id_opcode), .regDst(id_regDst),   .aluSrc(id_aluSrc),
        .memToReg(id_memToReg), .regWrite(id_regWrite),
        .memRead(id_memRead),   .memWrite(id_memWrite),
        .branchEq(id_branchEq), .branchNe(id_branchNe),
        .jump(id_jump), .jal(id_jal), .aluOp(id_aluOp)
    );
    jrControl JR_CTRL (.opcode(id_opcode), .funct(id_funct), .jr(id_jr));

    wire [31:0] id_ex_NPC, id_ex_A, id_ex_B, id_ex_Imm;
    wire [4:0]  id_ex_RS, id_ex_RT, id_ex_RD;
    wire        id_ex_RegDst, id_ex_ALUSrc;
    wire [3:0]  id_ex_ALUOp;
    wire        id_ex_BranchEq, id_ex_BranchNe;
    wire        id_ex_MemRead, id_ex_MemWrite;
    wire        id_ex_RegWrite, id_ex_MemToReg, id_ex_Jal;
    wire        id_ex_IsMul, id_ex_IsDiv;

    hazardDetectionUnit HDU (
        .id_ex_MemRead(id_ex_MemRead), .id_ex_RT(id_ex_RT),
        .if_id_RS(id_RS), .if_id_RT(id_RT),
        .PCWrite(hdu_PCWrite), .IF_IDWrite(hdu_IF_IDWrite), .ID_EXStall(hdu_ID_EXStall)
    );

    wire [31:0] id_signImm, id_zeroImm, id_imm;
    wire        id_immSelect;
    signExtend SEXT (.in(id_imm16), .out(id_signImm));
    zeroExtend ZEXT (.in(id_imm16), .out(id_zeroImm));
    sext_or_zext_control SEXT_OR_ZEXT_CTRL (.aluOp(id_aluOp), .sext_or_zext(id_immSelect));
    mux2 #(.width(32)) IMM_MUX (
        .in0(id_signImm), .in1(id_zeroImm), .s(id_immSelect), .out(id_imm)
    );

    wire [31:0] mem_wb_NPC, mem_wb_LMD, mem_wb_AluOut;
    wire [4:0]  mem_wb_RD;
    wire        mem_wb_RegWrite, mem_wb_MemToReg, mem_wb_Jal;
    wire        wb_regWrite;
    wire [4:0]  wb_regDest;
    wire [31:0] wb_writeData, wb_writeData_final;

    regFile REGFILE (
        .clock(clock), .reset(reset), .regWrite(wb_regWrite),
        .rn1(id_RS), .rn2(id_RT), .wn(wb_regDest), .wd(wb_writeData_final),
        .rd1(id_rd1), .rd2(id_rd2), .r1(r1), .r2(r2)
    );

    id_ex ID_EX (
        .clock(clock), .reset(reset),
        .id_ex_flush(mem_PCSrc | hdu_ID_EXStall), .id_ex_stall(fxpu_stall_id),
        .id_ex_NPC_in(if_id_NPC),
        .id_ex_A_in(id_rd1),     .id_ex_B_in(id_rd2),
        .id_ex_Imm_in(id_imm),
        .id_ex_RS_in(id_RS),     .id_ex_RT_in(id_RT),   .id_ex_RD_in(id_RD),
        .id_ex_RegDst_in(id_regDst),   .id_ex_ALUSrc_in(id_aluSrc),
        .id_ex_ALUOp_in(id_aluOp),
        .id_ex_BranchEq_in(id_branchEq), .id_ex_BranchNe_in(id_branchNe),
        .id_ex_MemRead_in(id_memRead),   .id_ex_MemWrite_in(id_memWrite),
        .id_ex_RegWrite_in(id_regWrite), .id_ex_MemToReg_in(id_memToReg),
        .id_ex_Jal_in(id_jal),
        .id_ex_IsMul_in(id_isMul),       .id_ex_IsDiv_in(id_isDiv),
        .id_ex_NPC_out(id_ex_NPC),
        .id_ex_A_out(id_ex_A),   .id_ex_B_out(id_ex_B),
        .id_ex_Imm_out(id_ex_Imm),
        .id_ex_RS_out(id_ex_RS), .id_ex_RT_out(id_ex_RT), .id_ex_RD_out(id_ex_RD),
        .id_ex_RegDst_out(id_ex_RegDst),   .id_ex_ALUSrc_out(id_ex_ALUSrc),
        .id_ex_ALUOp_out(id_ex_ALUOp),
        .id_ex_BranchEq_out(id_ex_BranchEq), .id_ex_BranchNe_out(id_ex_BranchNe),
        .id_ex_MemRead_out(id_ex_MemRead),   .id_ex_MemWrite_out(id_ex_MemWrite),
        .id_ex_RegWrite_out(id_ex_RegWrite), .id_ex_MemToReg_out(id_ex_MemToReg),
        .id_ex_Jal_out(id_ex_Jal),
        .id_ex_IsMul_out(id_ex_IsMul),       .id_ex_IsDiv_out(id_ex_IsDiv)
    );

    wire [31:0] ex_mem_NPC, ex_mem_BranchTarget, ex_mem_AluOut, ex_mem_B;
    wire [4:0]  ex_mem_RD;
    wire        ex_mem_Zero, ex_mem_BranchEq, ex_mem_BranchNe;
    wire        ex_mem_MemRead, ex_mem_MemWrite, ex_mem_RegWrite, ex_mem_MemToReg, ex_mem_Jal;
    wire [1:0]  forwardA, forwardB;
    wire [31:0] forwardMuxA_out, forwardMuxB_out;

    forwardingUnit FORWARD_UNIT (
        .id_ex_RS(id_ex_RS),             .id_ex_RT(id_ex_RT),
        .ex_mem_RegWrite(ex_mem_RegWrite), .ex_mem_RD(ex_mem_RD),
        .mem_wb_RegWrite(mem_wb_RegWrite), .mem_wb_RD(mem_wb_RD),
        .forwardMuxASelect(forwardA),      .forwardMuxBSelect(forwardB)
    );
    mux4 #(.width(32)) FORWARD_MUX_A (
        .in0(id_ex_A), .in1(wb_writeData_final), .in2(ex_mem_AluOut), .in3(32'b0),
        .s(forwardA), .out(forwardMuxA_out)
    );
    mux4 #(.width(32)) FORWARD_MUX_B (
        .in0(id_ex_B), .in1(wb_writeData_final), .in2(ex_mem_AluOut), .in3(32'b0),
        .s(forwardB), .out(forwardMuxB_out)
    );

    wire [4:0] ex_regDest, ex_regDest_final;
    mux2 #(.width(5)) REGDST_MUX (
        .in0(id_ex_RT), .in1(id_ex_RD), .s(id_ex_RegDst), .out(ex_regDest)
    );
    mux2 #(.width(5)) JAL_REGDST_MUX (
        .in0(ex_regDest), .in1(5'd31), .s(id_ex_Jal), .out(ex_regDest_final)
    );

    wire [31:0] ex_aluB;
    mux2 #(.width(32)) ALUSRC_MUX (
        .in0(forwardMuxB_out), .in1(id_ex_Imm), .s(id_ex_ALUSrc), .out(ex_aluB)
    );

    wire [3:0]  ex_aluOp;
    wire [31:0] ex_aluResult;
    wire        ex_zero;
    aluControl ALU_CTRL (.aluOp(id_ex_ALUOp), .func(id_ex_Imm[5:0]), .op(ex_aluOp));
    alu ALU (
        .a(forwardMuxA_out), .b(ex_aluB), .op(ex_aluOp),
        .result(ex_aluResult), .zero(ex_zero)
    );

    reg  fxpu_active;
    wire fxpu_busy, fxpu_done;
    wire [31:0] fxpu_result;
    wire fxpu_start = (id_ex_IsMul | id_ex_IsDiv) & ~fxpu_active;

    always @(posedge clock or posedge reset) begin
        if (reset)         fxpu_active <= 1'b0;
        else if (fxpu_start) fxpu_active <= 1'b1;
        else if (fxpu_done)  fxpu_active <= 1'b0;
    end

    assign fxpu_stall_id  = fxpu_busy | fxpu_start;
    assign fxpu_stall_all = fxpu_busy;

    fxpu FXPU (
        .clock(clock), .reset(reset),
        .start(fxpu_start), .isDiv(id_ex_IsDiv),
        .a(forwardMuxA_out), .b(forwardMuxB_out),
        .f(5'd8),            // *** CHANGED from 5'd0: correct 24.8 FP scale ***
        .result(fxpu_result), .busy(fxpu_busy), .done(fxpu_done)
    );

    wire [31:0] ex_aluResult_final = (id_ex_IsMul | id_ex_IsDiv) ? fxpu_result : ex_aluResult;

    wire [31:0] ex_shiftedImm, ex_branchTarget;
    shiftLeft2 SL2 (.in(id_ex_Imm), .out(ex_shiftedImm));
    adder BRANCH_ADDER (.a(id_ex_NPC), .b(ex_shiftedImm), .sum(ex_branchTarget));

    ex_mem EX_MEM (
        .clock(clock), .reset(reset), .ex_mem_flush(mem_PCSrc), .ex_mem_stall(fxpu_stall_all),
        .ex_mem_NPC_in(id_ex_NPC),
        .ex_mem_BranchTarget_in(ex_branchTarget), .ex_mem_Zero_in(ex_zero),
        .ex_mem_AluOut_in(ex_aluResult_final),     .ex_mem_B_in(forwardMuxB_out),
        .ex_mem_RD_in(ex_regDest_final),
        .ex_mem_BranchEq_in(id_ex_BranchEq), .ex_mem_BranchNe_in(id_ex_BranchNe),
        .ex_mem_MemRead_in(id_ex_MemRead),    .ex_mem_MemWrite_in(id_ex_MemWrite),
        .ex_mem_RegWrite_in(id_ex_RegWrite),  .ex_mem_MemToReg_in(id_ex_MemToReg),
        .ex_mem_Jal_in(id_ex_Jal),
        .ex_mem_NPC_out(ex_mem_NPC),
        .ex_mem_BranchTarget_out(ex_mem_BranchTarget), .ex_mem_Zero_out(ex_mem_Zero),
        .ex_mem_AluOut_out(ex_mem_AluOut),             .ex_mem_B_out(ex_mem_B),
        .ex_mem_RD_out(ex_mem_RD),
        .ex_mem_BranchEq_out(ex_mem_BranchEq), .ex_mem_BranchNe_out(ex_mem_BranchNe),
        .ex_mem_MemRead_out(ex_mem_MemRead),    .ex_mem_MemWrite_out(ex_mem_MemWrite),
        .ex_mem_RegWrite_out(ex_mem_RegWrite),  .ex_mem_MemToReg_out(ex_mem_MemToReg),
        .ex_mem_Jal_out(ex_mem_Jal)
    );

    assign mem_PCSrc = (ex_mem_BranchEq & ex_mem_Zero) | (ex_mem_BranchNe & ~ex_mem_Zero);
    mux2 #(.width(32)) PC_MUX (
        .in0(pc_plus4), .in1(ex_mem_BranchTarget), .s(mem_PCSrc), .out(branchMuxOut)
    );

    wire [31:0] mem_readData;
    memory DMEM (
        .clock(clock), .reset(reset),
        .memWrite(ex_mem_MemWrite), .memRead(ex_mem_MemRead),
        .address(ex_mem_AluOut),    .writeData(ex_mem_B),
        .readData(mem_readData),
        .memMappedIO({{(256-inputs){1'b0}}, memMappedIO})
    );

    mem_wb MEM_WB (
        .clock(clock), .reset(reset), .mem_wb_stall(fxpu_stall_all),
        .mem_wb_NPC_in(ex_mem_NPC),
        .mem_wb_LMD_in(mem_readData),      .mem_wb_AluOut_in(ex_mem_AluOut),
        .mem_wb_RD_in(ex_mem_RD),
        .mem_wb_RegWrite_in(ex_mem_RegWrite), .mem_wb_MemToReg_in(ex_mem_MemToReg),
        .mem_wb_Jal_in(ex_mem_Jal),
        .mem_wb_NPC_out(mem_wb_NPC),
        .mem_wb_LMD_out(mem_wb_LMD),       .mem_wb_AluOut_out(mem_wb_AluOut),
        .mem_wb_RD_out(mem_wb_RD),
        .mem_wb_RegWrite_out(mem_wb_RegWrite), .mem_wb_MemToReg_out(mem_wb_MemToReg),
        .mem_wb_Jal_out(mem_wb_Jal)
    );

    mux2 #(.width(32)) MEMTOREG_MUX (
        .in0(mem_wb_AluOut), .in1(mem_wb_LMD), .s(mem_wb_MemToReg), .out(wb_writeData)
    );
    mux2 #(.width(32)) JAL_MEMTOREG_MUX (
        .in0(wb_writeData), .in1(mem_wb_NPC), .s(mem_wb_Jal), .out(wb_writeData_final)
    );

    assign wb_regWrite = mem_wb_RegWrite;
    assign wb_regDest  = mem_wb_RD;

endmodule