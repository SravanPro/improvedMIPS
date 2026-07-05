`timescale 1ns / 1ps

module analogTranslator(
    input white, black,brown,red,
    output right, left, up, down
);

    assign left = white;
    assign down = brown;
    
    assign right = ~black;
    assign up = ~red;

endmodule
