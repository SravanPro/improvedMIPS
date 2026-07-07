#include <stdio.h>
#include <math.h>
#include <stdint.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

int main(void)
{
    FILE *file = fopen("output.txt", "w");
    if (file == NULL)
    {
        printf("Error: Could not create output.txt\n");
        return 1;
    }

    fprintf(file, "// Sine LUT (0-90 degrees, 3-degree steps)\n");
    fprintf(file, "// Format: Signed 16-bit 8.8 Fixed Point (Big Endian)\n\n");

    int addr = 0;

    for (int angle = 0; angle <= 90; angle += 3)
    {
        double radians = angle * M_PI / 180.0;
        double sine = sin(radians);

        // 8.8 fixed-point
        int16_t fixed = (int16_t)round(sine * 256.0);

        uint8_t msb = (fixed >> 8) & 0xFF;
        uint8_t lsb = fixed & 0xFF;

        // fprintf(file,
        //     "mem[%2d] = 8'h%02X; mem[%2d] = 8'h%02X;   // %2d°  sin=% .6f  fixed=%4d (0x%04X)\n",
        //     addr, msb,
        //     addr + 1, lsb,
        //     angle,
        //     sine,
        //     fixed,
        //     (uint16_t)fixed);

        fprintf(file,
            "mem[%2d] = 8'h%02X; mem[%2d] = 8'h%02X;\n",
            addr, msb,
            addr + 1, lsb);

        addr += 2;
    }

    fclose(file);

    printf("Success! Generated %d entries (%d bytes).\n", 31, 31 * 2);

    return 0;
}