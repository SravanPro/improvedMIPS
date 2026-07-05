`timescale 1ns / 1ps

module spi (
    input            clock,
    input            reset,
    input  [8191:0]  fb,
    output reg       sck,
    output reg       sda,
    output reg       res,
    output reg       dc,
    output reg       cs
);

localparam CLK_DIV     = 3'd4;
localparam INIT_LEN    = 5'd23;
localparam RESET_TICKS = 14'd9999;

reg [7:0] init_rom [0:22];
initial begin
    init_rom[ 0] = 8'hAE; init_rom[ 1] = 8'hD5; init_rom[ 2] = 8'hF0;
    init_rom[ 3] = 8'hA8; init_rom[ 4] = 8'h3F; init_rom[ 5] = 8'hD3;
    init_rom[ 6] = 8'h00; init_rom[ 7] = 8'h40; init_rom[ 8] = 8'h8D;
    init_rom[ 9] = 8'h14; init_rom[10] = 8'h20; init_rom[11] = 8'h02;
    init_rom[12] = 8'hA1; init_rom[13] = 8'hC8; init_rom[14] = 8'hDA;
    init_rom[15] = 8'h12; init_rom[16] = 8'h81; init_rom[17] = 8'hCF;
    init_rom[18] = 8'hD9; init_rom[19] = 8'hF1; init_rom[20] = 8'hDB;
    init_rom[21] = 8'h40; init_rom[22] = 8'hAF;
end

function [7:0] page_byte;
    input [2:0] p;
    input [6:0] c;
    reg [12:0] base;
    begin
        base = {p, 10'b0};
        page_byte[0] = fb[base +   0 + c];
        page_byte[1] = fb[base + 128 + c];
        page_byte[2] = fb[base + 256 + c];
        page_byte[3] = fb[base + 384 + c];
        page_byte[4] = fb[base + 512 + c];
        page_byte[5] = fb[base + 640 + c];
        page_byte[6] = fb[base + 768 + c];
        page_byte[7] = fb[base + 896 + c];
    end
endfunction

// ---------------------------------------------------------------------------
// SPI shift engine  - drives sck, sda ONLY
// ---------------------------------------------------------------------------
reg [7:0]  shift_reg;
reg [2:0]  bit_cnt;
reg [2:0]  clk_cnt;
reg        sck_r;
reg        spi_busy;
reg        spi_done;
reg        spi_load;
reg [7:0]  data_byte;
reg        data_dc;      // sampled by FSM to set dc before asserting spi_load

always @(posedge clock) begin
    spi_done <= 1'b0;

    if (reset) begin
        shift_reg <= 8'h00;
        bit_cnt   <= 3'd7;
        clk_cnt   <= 3'd0;
        sck_r     <= 1'b0;
        sck       <= 1'b0;
        sda       <= 1'b0;
        spi_busy  <= 1'b0;
    end else begin
        if (spi_load && !spi_busy) begin
            shift_reg <= data_byte;
            sda       <= data_byte[7];
            // *** dc and cs are NOT touched here - FSM owns them ***
            bit_cnt   <= 3'd7;
            clk_cnt   <= 3'd0;
            sck_r     <= 1'b0;
            sck       <= 1'b0;
            spi_busy  <= 1'b1;
        end else if (spi_busy) begin
            if (clk_cnt == CLK_DIV - 1) begin
                clk_cnt <= 3'd0;
                sck_r   <= ~sck_r;
                sck     <= ~sck_r;

                if (!sck_r) begin
                    // Rising edge - data already stable
                end else begin
                    // Falling edge - shift next bit or finish
                    if (bit_cnt == 3'd0) begin
                        spi_busy <= 1'b0;
                        spi_done <= 1'b1;
                        sck      <= 1'b0;
                    end else begin
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        sda       <= shift_reg[6];
                        bit_cnt   <= bit_cnt - 3'd1;
                    end
                end
            end else begin
                clk_cnt <= clk_cnt + 3'd1;
            end
        end
    end
end

// ---------------------------------------------------------------------------
// Control FSM  - sole driver of cs, dc, res
// ---------------------------------------------------------------------------
localparam [2:0]
    S_RESET      = 3'd0,
    S_RESET_WAIT = 3'd1,
    S_INIT       = 3'd2,
    S_PAGE_CMD0  = 3'd3,
    S_PAGE_CMD1  = 3'd4,
    S_PAGE_CMD2  = 3'd5,
    S_DATA       = 3'd6,
    S_PAGE_END   = 3'd7;

reg [2:0]  state;
reg [13:0] wait_cnt;
reg [4:0]  init_idx;
reg [2:0]  page;
reg [6:0]  col;
reg [7:0]  col_byte_r;

// Helper: stage a byte for the SPI engine.
// dc must be set BEFORE calling fsm_send so the SPI engine
// sees a stable dc when it latches on the first SCK edge.
task fsm_send;
    input [7:0] b;
    input       is_data;
    begin
        dc        <= is_data;   // FSM drives dc here
        data_byte <= b;
        spi_load  <= 1'b1;
    end
endtask

always @(posedge clock) begin
    spi_load <= 1'b0;

    if (reset) begin
        state    <= S_RESET;
        res      <= 1'b0;
        cs       <= 1'b1;
        dc       <= 1'b0;
        wait_cnt <= 14'd0;
        init_idx <= 5'd0;
        page     <= 3'd0;
        col      <= 7'd0;
    end else begin
        case (state)

            S_RESET: begin
                res      <= 1'b0;
                cs       <= 1'b1;
                wait_cnt <= wait_cnt + 14'd1;
                if (wait_cnt == RESET_TICKS) begin
                    res      <= 1'b1;
                    wait_cnt <= 14'd0;
                    state    <= S_RESET_WAIT;
                end
            end

            S_RESET_WAIT: begin
                wait_cnt <= wait_cnt + 14'd1;
                if (wait_cnt == RESET_TICKS) begin
                    wait_cnt <= 14'd0;
                    init_idx <= 5'd0;
                    state    <= S_INIT;
                end
            end

            S_INIT: begin
                if (!spi_busy && !spi_load) begin
                    if (init_idx == INIT_LEN) begin
                        cs    <= 1'b1;
                        page  <= 3'd0;
                        col   <= 7'd0;
                        state <= S_PAGE_CMD0;
                    end else begin
                        cs <= 1'b0;                          // FSM asserts CS
                        fsm_send(init_rom[init_idx], 1'b0);
                        init_idx <= init_idx + 5'd1;
                    end
                end
            end

            S_PAGE_CMD0: begin
                if (!spi_busy && !spi_load) begin
                    cs <= 1'b0;
                    fsm_send(8'hB0 | {5'b0, page}, 1'b0);
                    state <= S_PAGE_CMD1;
                end
            end

            S_PAGE_CMD1: begin
                if (!spi_busy && !spi_load) begin
                    fsm_send(8'h00, 1'b0);
                    state <= S_PAGE_CMD2;
                end
            end

            S_PAGE_CMD2: begin
                if (!spi_busy && !spi_load) begin
                    fsm_send(8'h10, 1'b0);
                    col        <= 7'd0;
                    col_byte_r <= page_byte(page, 7'd0);
                    state      <= S_DATA;
                end
            end

            S_DATA: begin
                if (!spi_busy && !spi_load) begin
                    fsm_send(col_byte_r, 1'b1);
                    if (col == 7'd127) begin
                        state <= S_PAGE_END;
                    end else begin
                        col        <= col + 7'd1;
                        col_byte_r <= page_byte(page, col + 7'd1);
                    end
                end
            end

            S_PAGE_END: begin
                if (spi_done) begin
                    cs <= 1'b1;
                    page  <= (page == 3'd7) ? 3'd0 : page + 3'd1;
                    state <= S_PAGE_CMD0;
                end
            end

            default: state <= S_RESET;

        endcase
    end
end

endmodule