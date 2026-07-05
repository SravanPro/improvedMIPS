#include <stdio.h>
#include <math.h>
#include <stdint.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

int main() {
    // Open output file
    FILE *file = fopen("output.txt", "w");
    if (file == NULL) {
        printf("Error: Could not create output.txt\n");
        return 1;
    }

    fprintf(file, "// Sine LUT for angles 0 to 360 (24.8 Fixed Point, Big-Endian Layout)\n");

    for (int angle = 0; angle <= 360; angle++) {
        // Convert angle to radians and calculate sine
        double radians = angle * M_PI / 180.0;
        double sine_val = sin(radians);
        
        // Scale to 24.8 fixed point and round to the nearest whole integer
        int32_t fixed_val = (int32_t)round(sine_val * 256.0);
        
        // Extract individual bytes (32-bit signed two's complement split)
        uint8_t byte0 = (fixed_val >> 24) & 0xFF; // MSB (writeData[31:24])
        uint8_t byte1 = (fixed_val >> 16) & 0xFF; //     (writeData[23:16])
        uint8_t byte2 = (fixed_val >> 8)  & 0xFF; //     (writeData[15:8])
        uint8_t byte3 = fixed_val & 0xFF;         // LSB (writeData[7:0])
        
        // Each 32-bit word takes up 4 bytes of memory space
        int base_addr = angle * 4;
        
        // Write out the Verilog initial block format
        fprintf(file, "mem[%d] = 8'h%02X; mem[%d] = 8'h%02X; mem[%d] = 8'h%02X; mem[%d] = 8'h%02X;\n",
                base_addr,     byte0,
                base_addr + 1, byte1,
                base_addr + 2, byte2,
                base_addr + 3, byte3);
    }

    fclose(file);
    printf("Success! 'output.txt' generated with 361 entries (0 to 360 degrees).\n");
    return 0;
}