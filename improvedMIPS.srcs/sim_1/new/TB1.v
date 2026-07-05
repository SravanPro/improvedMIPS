`timescale 1ns / 1ps

module TB1 ();

    reg clock, reset;

    reg white, black, brown, red, gameRst, erase, draw;

    integer outfile;

    parent uut(
        .clock(clock),
        .reset(reset),
        .white(white),
        .black(black),
        .brown(brown),
        .red(red),
        .gameRst(gameRst),
        .erase(erase),
        .draw(draw)
    );

    always #5 clock = ~clock;

    task dumpColumnHeights;
    begin
        outfile = $fopen("column_heights.txt", "w");

        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h0);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h1);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h2);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h3);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h4);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h5);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h6);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h7);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h8);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h9);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h10);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h11);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h12);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h13);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h14);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h15);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h16);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h17);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h18);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h19);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h20);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h21);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h22);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h23);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h24);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h25);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h26);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h27);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h28);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h29);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h30);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h31);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h32);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h33);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h34);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h35);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h36);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h37);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h38);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h39);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h40);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h41);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h42);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h43);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h44);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h45);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h46);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h47);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h48);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h49);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h50);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h51);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h52);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h53);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h54);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h55);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h56);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h57);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h58);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h59);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h60);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h61);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h62);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h63);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h64);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h65);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h66);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h67);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h68);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h69);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h70);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h71);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h72);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h73);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h74);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h75);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h76);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h77);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h78);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h79);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h80);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h81);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h82);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h83);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h84);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h85);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h86);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h87);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h88);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h89);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h90);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h91);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h92);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h93);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h94);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h95);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h96);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h97);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h98);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h99);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h100);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h101);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h102);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h103);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h104);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h105);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h106);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h107);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h108);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h109);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h110);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h111);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h112);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h113);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h114);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h115);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h116);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h117);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h118);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h119);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h120);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h121);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h122);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h123);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h124);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h125);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h126);
        $fdisplay(outfile, "%0d", uut.RAYCAST_RENDERER.h127);
        $fclose(outfile);
    end
    endtask

    initial begin
        clock = 0;
        reset = 1;

        white   = 0;
        black   = 0;
        brown   = 0;
        red     = 0;
        gameRst = 0;
        erase   = 0;
        draw    = 0;

        #300 reset = 0;

        // Snapshot exactly at t = 1 ms
        #999700;
        dumpColumnHeights();

        // Original delays (unchanged)
        #2385000;
        #10000;

        #200 $finish;
    end

endmodule