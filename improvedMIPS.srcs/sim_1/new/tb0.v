`timescale 1ns / 1ps

module tb0 ();
    reg clock, reset;
    reg draw, erase, gameRst, speedInc, speedDec;
    reg white, black, brown, red;

    wire [3:0] speedOut;

    wire memWrite = uut.PIPELINE.DMEM.memWrite;

    parent #(.inputs(256), .SIM_MODE(1)) uut (
        .clock(clock), .reset(reset),
        .white(white), .black(black), .brown(brown), .red(red),
        .gameRst(gameRst), .erase(erase), .draw(draw),
        .speedInc(speedInc), .speedDec(speedDec),
        .speedOut(speedOut)
    );

    always #5 clock = ~clock;

    // ---- debug trace wires (hierarchical refs into pipeline/DMEM internals) ----
    wire [31:0] dbg_pc        = uut.PIPELINE.pc_out;
    wire [31:0] dbg_instr     = uut.PIPELINE.if_id_IR;
    wire [5:0]  dbg_opcode    = uut.PIPELINE.id_opcode;
    wire [5:0]  dbg_funct     = uut.PIPELINE.id_funct;
    wire        dbg_idjump    = uut.PIPELINE.id_jump;
    wire        dbg_idjal     = uut.PIPELINE.id_jal;
    wire        dbg_idjr      = uut.PIPELINE.id_jr;
    wire        dbg_branchEq  = uut.PIPELINE.id_branchEq;
    wire        dbg_branchNe  = uut.PIPELINE.id_branchNe;
    wire        dbg_memPCSrc  = uut.PIPELINE.mem_PCSrc;
    wire        dbg_hdu_pcw   = uut.PIPELINE.hdu_PCWrite;
    wire        dbg_fxpu_busy = uut.PIPELINE.fxpu_busy;
    wire        dbg_fxpu_start= uut.PIPELINE.fxpu_start;
    wire        dbg_fxpu_done = uut.PIPELINE.fxpu_done;
    wire        dbg_ismul     = uut.PIPELINE.id_ex_IsMul;
    wire        dbg_isdiv     = uut.PIPELINE.id_ex_IsDiv;
    wire [31:0] dbg_r5_px     = uut.PIPELINE.REGFILE.regBank[5];
    wire [31:0] dbg_r6_py     = uut.PIPELINE.REGFILE.regBank[6];
    wire [31:0] dbg_r7_ang    = uut.PIPELINE.REGFILE.regBank[7];
    wire [31:0] dbg_ex_alub   = uut.PIPELINE.ex_aluB;
    wire [31:0] dbg_aluResult = uut.PIPELINE.ex_aluResult;

    integer trace_i;
    initial begin
        @(negedge reset);
        for (trace_i = 0; trace_i < 300; trace_i = trace_i + 1) begin
            @(posedge clock);
            #1;
            $display("t=%0t pc=%0d(0x%h) instr=0x%h op=%b funct=%b jump=%b jal=%b jr=%b beq=%b bne=%b memPCSrc=%b hdu_pcw=%b fxpu_busy=%b fxpu_start=%b fxpu_done=%b ismul=%b isdiv=%b r5=%0d r6=%0d r7=%0d aluB=%0d aluRes=%0d",
                $time, dbg_pc, dbg_pc, dbg_instr, dbg_opcode, dbg_funct,
                dbg_idjump, dbg_idjal, dbg_idjr, dbg_branchEq, dbg_branchNe, dbg_memPCSrc, dbg_hdu_pcw,
                dbg_fxpu_busy, dbg_fxpu_start, dbg_fxpu_done, dbg_ismul, dbg_isdiv,
                $signed(dbg_r5_px), $signed(dbg_r6_py), $signed(dbg_r7_ang),
                $signed(dbg_ex_alub), $signed(dbg_aluResult));
        end
    end

    // File logging: dump COL_HEIGHTS_INT (128 csv ints, 0-64) on memWrite rising edge
    integer frame_file, col;
    reg prev_memWrite;

    initial begin
        prev_memWrite = 0;
        frame_file = $fopen("frames.txt", "w");
        $fclose(frame_file);
    end

    task dump;
        begin
            frame_file = $fopen("frames.txt", "a");
            for (col = 0; col < 128; col = col + 1) begin
                $fwrite(frame_file, "%0d", uut.PIPELINE.DMEM.mem[32'h3180 + col*4 + 3]);
                if (col != 127) $fwrite(frame_file, ",");
            end
            $fwrite(frame_file, "\n");
            $fclose(frame_file);
        end
    endtask

    always @(posedge clock) begin
        if (memWrite && !prev_memWrite) dump();
        prev_memWrite <= memWrite;
    end

    // Joystick logic: maps logical DIR to wire polarities (same as painterTB)
    task set_joystick(input reg r, input reg l, input reg u, input reg d);
        begin
            white = l;
            brown = d;
            black = ~r;
            red   = ~u;
        end
    endtask

    initial begin
        {clock, reset, draw, erase, gameRst, speedInc, speedDec} = 0;
        set_joystick(0,0,0,0);

        #1000 reset = 1; #100 reset = 0;

        repeat(200) begin
            @(posedge clock); #1;
            $display("t=%0t pc=%0h instr=%08h op=%06b funct=%06b | fxpu_start=%b busy=%b done=%b IsMul=%b IsDiv=%b | PCWrite=%b stall_id=%b mem_PCSrc=%b memWrite=%b",
                $time, uut.PIPELINE.pc_out, uut.PIPELINE.if_instruction,
                uut.PIPELINE.id_opcode, uut.PIPELINE.id_funct,
                uut.PIPELINE.fxpu_start, uut.PIPELINE.fxpu_busy, uut.PIPELINE.fxpu_done,
                uut.PIPELINE.id_ex_IsMul, uut.PIPELINE.id_ex_IsDiv,
                uut.PIPELINE.hdu_PCWrite, uut.PIPELINE.fxpu_stall_id, uut.PIPELINE.mem_PCSrc,
                uut.PIPELINE.ex_mem_MemWrite);
        end

        repeat(1000) @(posedge clock);   // boot up

        $display("Moving forward (up)...");
        set_joystick(0, 0, 1, 0);        // up
        repeat(60000) @(posedge clock);
        set_joystick(0,0,0,0);

        repeat(2000) @(posedge clock);

        $display("Rotating (draw)...");
        draw = 1;
        repeat(60000) @(posedge clock);
        draw = 0;

        repeat(2000) @(posedge clock);

        $display("Strafing left...");
        set_joystick(0, 1, 0, 0);        // left
        repeat(60000) @(posedge clock);
        set_joystick(0,0,0,0);

        repeat(2000) @(posedge clock);

        $display("GameRst pulse...");
        gameRst = 1;
        repeat(50) @(posedge clock);
        gameRst = 0;

        repeat(5000) @(posedge clock);

        $display("Simulation finished. Check frames.txt");
        $finish;
    end
endmodule