#include <stdint.h>

typedef int32_t fx24_8;

/* -------------------------------------------------
   Registers (equivalent to MIPS r0-r31)
   ------------------------------------------------- */

int32_t r0,  r1,  r2,  r3,  r4,  r5,  r6,  r7;
int32_t r8,  r9,  r10, r11, r12, r13, r14, r15;
int32_t r16, r17, r18, r19, r20, r21, r22, r23;
int32_t r24, r25, r26, r27, r28, r29, r30, r31;

/* -------------------------------------------------
   DMEM
   ------------------------------------------------- */

uint8_t memory[16384];

/* -------------------------------------------------
   LUTs
   ------------------------------------------------- */

fx24_8 SIN_LUT[1440];
fx24_8 COS_LUT[1440];

/* -------------------------------------------------
   Map
   ------------------------------------------------- */

uint16_t map[16];

/* -------------------------------------------------
   Renderer output
   ------------------------------------------------- */

uint32_t columnHeightFX[128];
uint32_t columnHeightInt[128];

/* -------------------------------------------------
   Helpers
   ------------------------------------------------- */

int mapTile(int x, int y)
{
    return (map[y] >> (15 - x)) & 1;
}

/* -------------------------------------------------
   Main
   ------------------------------------------------- */

int main(void)
{
    //------------------------------------------------
    // Spawn state
    //------------------------------------------------

    fx24_8 playerX = 7 << 8 | 128;      // 7.5
    fx24_8 playerY = 8 << 8 | 128;      // 8.5

    int angleIdx = 720;

    while (1)
    {
        //------------------------------------------------
        // Read buttons
        //------------------------------------------------

        int up;
        int down;
        int left;
        int right;
        int rotLeft;
        int rotRight;
        int gameReset;

        //------------------------------------------------
        // Reset
        //------------------------------------------------

        if (gameReset)
        {
            playerX = 7 << 8 | 128;
            playerY = 8 << 8 | 128;
            angleIdx = 720;
        }

        //------------------------------------------------
        // Movement
        //------------------------------------------------

        fx24_8 dirX = COS_LUT[angleIdx];
        fx24_8 dirY = SIN_LUT[angleIdx];

        fx24_8 moveX = 0;
        fx24_8 moveY = 0;

        if (up)
        {
            moveX += dirX;
            moveY += dirY;
        }

        if (down)
        {
            moveX -= dirX;
            moveY -= dirY;
        }

        if (left)
        {
            int idx = (angleIdx + 1080) % 1440;

            moveX += COS_LUT[idx];
            moveY += SIN_LUT[idx];
        }

        if (right)
        {
            int idx = (angleIdx + 360) % 1440;

            moveX += COS_LUT[idx];
            moveY += SIN_LUT[idx];
        }

        //------------------------------------------------
        // Collision
        //------------------------------------------------

        fx24_8 newX = playerX + moveX;
        fx24_8 newY = playerY + moveY;

        // Axis-separated collision goes here.

        playerX = newX;
        playerY = newY;

        //------------------------------------------------
        // Rotation
        //------------------------------------------------

        if (rotLeft)
            angleIdx = (angleIdx + 1436) % 1440;

        if (rotRight)
            angleIdx = (angleIdx + 4) % 1440;

        //------------------------------------------------
        // Raycasting
        //------------------------------------------------

        int rayAngle = angleIdx - 32;

        if (rayAngle < 0)
            rayAngle += 1440;

        for (int ray = 0; ray < 128; ray++)
        {
            fx24_8 rayDirX = COS_LUT[rayAngle];
            fx24_8 rayDirY = SIN_LUT[rayAngle];

            //------------------------------------------------
            // DDA
            //------------------------------------------------

            int mapX = playerX >> 8;
            int mapY = playerY >> 8;

            fx24_8 deltaDistX;
            fx24_8 deltaDistY;

            fx24_8 sideDistX;
            fx24_8 sideDistY;

            int stepX;
            int stepY;

            int side = 0;

            // Compute deltaDistX
            // Compute deltaDistY
            // Compute initial sideDist
            // Compute stepX/stepY

            int steps = 0;

            while (1)
            {
                if (sideDistX < sideDistY)
                {
                    sideDistX += deltaDistX;
                    mapX += stepX;
                    side = 0;
                }
                else
                {
                    sideDistY += deltaDistY;
                    mapY += stepY;
                    side = 1;
                }

                steps++;

                if (mapTile(mapX, mapY))
                    break;

                if (steps >= 32)
                    break;
            }

            //------------------------------------------------
            // Exact distance
            //------------------------------------------------

            fx24_8 distance;

            if (steps >= 32)
            {
                distance = 0x7FFFFFFF;
            }
            else if (side == 0)
            {
                distance =
                    ((mapX << 8) - playerX + ((stepX < 0) ? 256 : 0))
                    / rayDirX;
            }
            else
            {
                distance =
                    ((mapY << 8) - playerY + ((stepY < 0) ? 256 : 0))
                    / rayDirY;
            }

            if (distance < 0)
                distance = -distance;

            //------------------------------------------------
            // Projection
            //------------------------------------------------

            fx24_8 height = (100 << 16) / distance;

            if (height > (64 << 8))
                height = (64 << 8);

            columnHeightFX[ray] = height;
            columnHeightInt[ray] = height >> 8;

            //------------------------------------------------
            // Next ray
            //------------------------------------------------

            rayAngle++;

            if (rayAngle == 1440)
                rayAngle = 0;
        }
    }
}