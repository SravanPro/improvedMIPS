`timescale 1ns / 1ps

module mul_booth_radix4(
    input         clock,
    input         reset,
    input         start,
    input  [31:0] a,
    input  [31:0] b,
    output [63:0] product,
    output        busy,
    output        done
);

    // a = multiplicand, b = multiplier
    // booth recoding works on overlapping 3 bit windows of b, 2 bits at a time
    // 16 windows cover 32 bits plus the guard bit, so 16 cycles total

    reg [64:0] acc;        // accumulator, extra bit for sign safety during shifts
    reg [32:0] mcand_ext;  // multiplicand sign extended, used to build +-1x and +-2x
    reg [33:0] mplier;     // multiplier with guard bit appended at lsb
    reg [4:0]  count;
    reg        busy_r;
    reg        done_r;

    wire [2:0] window = mplier[2:0];

    // pick the partial product for this window
    reg [64:0] pp;
    always @(*) begin
        case (window)
            3'b000: pp = 65'b0;
            3'b001: pp = {{33{mcand_ext[32]}}, mcand_ext};        // +1x
            3'b010: pp = {{33{mcand_ext[32]}}, mcand_ext};        // +1x
            3'b011: pp = {{32{mcand_ext[32]}}, mcand_ext, 1'b0};  // +2x
            3'b100: pp = -{{32{mcand_ext[32]}}, mcand_ext, 1'b0}; // -2x
            3'b101: pp = -{{33{mcand_ext[32]}}, mcand_ext};       // -1x
            3'b110: pp = -{{33{mcand_ext[32]}}, mcand_ext};       // -1x
            3'b111: pp = 65'b0;
        endcase
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            acc        <= 65'b0;
            mcand_ext  <= 33'b0;
            mplier     <= 34'b0;
            count      <= 5'b0;
            busy_r     <= 1'b0;
            done_r     <= 1'b0;
        end
        else begin
            done_r <= 1'b0;

            if (start && !busy_r) begin
                // load operands, multiplier gets a 0 guard bit at the lsb
                acc        <= 65'b0;
                mcand_ext  <= {a[31], a};
                mplier     <= {b, 1'b0};
                count      <= 5'd0;
                busy_r     <= 1'b1;
            end
            else if (busy_r) begin
                // add this window's partial product, shifted into place, then shift window right by 2
                acc    <= (acc + (pp <<< (2*count))) ;
                mplier <= mplier >> 2;
                count  <= count + 5'd1;

                if (count == 5'd15) begin
                    busy_r <= 1'b0;
                    done_r <= 1'b1;
                end
            end
        end
    end

    assign product = acc[63:0];
    assign busy    = busy_r;
    assign done    = done_r;

endmodule