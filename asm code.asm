# DDA Raycaster — MIPS Assembly (final, corrected, $31 spill fix)
# Fixed-point format: 24.8 throughout.
#
# DMEM layout:
#   0x0000 - 0x05A3 : Sine LUT         (1444 bytes, 361 * 4)
#   0x05A4 - 0x0733 : Arena map        ( 400 bytes, 100 * 4, word-packed: value in LSB)
#   0x0734 - 0x0933 : Ray lengths      ( 512 bytes, 128 * 4, FP 24.8)
#   0x0934 - 0x0B33 : Column heights   ( 512 bytes, 128 * 4, integer)
#   0x0B34 - 0x0B43 : DDA scratch      (  16 bytes, 4 words)
#   0x0B44          : raycaster $31 spill (4 bytes, free padding word)
#
# Arena: 10x10 grid (row 0 = north/top, row 9 = south/bottom)
#   Byte value 1 = wall, 0 = empty.
#   Arena index for cell (arena_row, map_x) = (9 - map_y_from_bottom) * 10 + map_x
#   Byte offset = arena_idx * 4 (word-packed).
#
# map_y_from_bottom = floor((y_fp + 1280) / 256)  [0=south, 9=north]
# map_x             = floor((x_fp + 1280) / 256)  [0=west,  9=east]
#
# Scratch layout (base 0x0B34 = 2868):
#   [0x0B34] delta_dist_x (FP 24.8)
#   [0x0B38] delta_dist_y (FP 24.8)
#   [0x0B3C] step_x       (+1 = east, -1 = west)
#   [0x0B40] step_map_y   (+1 = north, -1 = south)
#   [0x0B44] raycaster's own return address ($31 spill, since it calls
#            jal cos / jal sin internally which would otherwise clobber $31)
#
# FOV: 128 deg, 128 rays, 1 deg/ray.
# Player start: x=0 (FP=0), y=-128 (FP =-0.5 units), theta=270 deg (FP=69120).
# theta=270 deg = south.  Center ray at 270 hits south wall first.
#
# FXPU note: mul uses f=8 (set by user in pipeline.v: .f(5'd8)).
#             div uses f=8 (same).
#   mul rd, rs, rt  -> rd = (rs * rt) >> 8   (FP 24.8 × FP 24.8 -> FP 24.8)
#   div rd, rs, rt  -> rd = (rs << 8) / rt   (FP result; see math comments)
#
# K=32: column height = (K<<8) / ray_len_fp = 8192 / ray_len_fp  (integer result)
#   At ray_len=0.5 units (FP=128): h = 8192/128 = 64 (full screen)
#   At ray_len=1.0 units (FP=256): h = 32
#   At ray_len=4.0 units (FP=1024): h = 8
#
# Hazard NOP rules followed:
#   - 3 NOPs before jr $31 (conservative)
#   - 3 NOPs between a write and a beq/bne that reads that register
#   - 3 NOPs between lw and any instruction that uses the loaded value
#   - mul/div: FXPU auto-stalls; result safely forwarded from EX_MEM


########################################
# INITIALIZATION
########################################
addi  $1,  $0,  0          # player x = 0 (FP)
addi  $2,  $0, -128        # player y = -0.5 units (FP)
# theta = 270 * 256 = 69120 = 0x10E00
lui   $3,  0x0001
ori   $3,  $3,  0x0E00     # theta = 270 deg (FP 24.8)

addi  $10, $0,  26          # coord step resolution (0.1 * 256 ≈ 26)
addi  $11, $0,  256         # 1 degree in FP (= 256)
addi  $12, $0,  1280        # +5 units in FP (= +1280)
sub   $13, $0,  $12         # -5 units in FP (= -1280)

lui   $30, 0xFFFF
ori   $30, $30, 0xFF00      # MMIO base

########################################
# MAIN LOOP
########################################
start:
lw  $4,  0($30)             # mmi0: x inc
lw  $5,  1($30)             # mmi1: x dec
lw  $6,  2($30)             # mmi2: y inc
lw  $7,  3($30)             # mmi3: y dec
lw  $8,  4($30)             # mmi4: theta inc
lw  $9,  5($30)             # mmi5: theta dec

# X movement: delta = cos(theta) * resolution
add   $29, $0, $3
jal   cos                   # $29 = cos(theta) in FP 24.8
mul   $28, $29, $10         # $28 = cos(theta) * 26, FP result

slt   $29, $1, $12          # $29 = 1 if x < +1280
nop
nop
nop
beq   $29, $0, skipXInc     # skip if x already at or past +5
beq   $4,  $0, skipXInc
add   $1,  $1,  $28
skipXInc:
slt   $29, $1, $13          # $29 = 1 if x < -1280
nop
nop
nop
bne   $29, $0, skipXDec     # skip if x already past -5 (below lower bound)
beq   $5,  $0, skipXDec
sub   $1,  $1,  $28
skipXDec:

# Y movement: delta = sin(theta) * resolution
add   $29, $0, $3
jal   sin                   # $29 = sin(theta) in FP 24.8
mul   $28, $29, $10

slt   $29, $2, $12
nop
nop
nop
beq   $29, $0, skipYInc
beq   $6,  $0, skipYInc
add   $2,  $2,  $28
skipYInc:
slt   $29, $2, $13
nop
nop
nop
bne   $29, $0, skipYDec
beq   $7,  $0, skipYDec
sub   $2,  $2,  $28
skipYDec:

# Theta management
beq   $8,  $0, skipThetaInc
add   $3,  $3,  $11
skipThetaInc:
beq   $9,  $0, skipThetaDec
sub   $3,  $3,  $11
skipThetaDec:

# Theta wrap: 360 * 256 = 92160 = 0x16800
lui   $29, 0x0001
ori   $29, $29, 0x6800

slt   $28, $3, $0
nop
nop
nop
beq   $28, $0, skipNegWrap
sub   $3,  $29, $11
skipNegWrap:

slt   $28, $3, $29
nop
nop
nop
bne   $28, $0, skipPosWrap
addi  $3,  $0, 0
skipPosWrap:

# Call raycaster then loop
jal   raycaster
j     start

########################################
# sin: input $29 (FP 24.8 degrees), output $29 = sin value (FP 24.8)
########################################
sin:
addi  $28, $0, 8
srlv  $29, $29, $28         # $29 = integer degrees (0-359)
addi  $28, $0, 2
sllv  $29, $29, $28         # $29 = byte offset = degrees * 4
lw    $29, 0($29)           # load from sine LUT at offset
nop
nop
nop
jr    $31

########################################
# cos: input $29 (FP 24.8 degrees), output $29 = cos value (FP 24.8)
# cos(x) = sin(x + 90), with wrap at 360.
########################################
cos:
addi  $28, $0, 8
srlv  $29, $29, $28         # integer degrees
addi  $29, $29, 90
addi  $28, $0, 360
slt   $28, $29, $28         # 1 if (degrees+90) < 360
nop
nop
nop
bne   $28, $0, skipCosWrap
addi  $29, $29, -360        # wrap: subtract 360
skipCosWrap:
addi  $28, $0, 2
sllv  $29, $29, $28         # byte offset
lw    $29, 0($29)           # load from LUT
nop
nop
nop
jr    $31

########################################
# raycaster: casts 128 rays.
# Writes FP ray lengths to [RAYLEN_BASE + i*4]
# Writes integer heights  to [CHEIGHT_BASE + i*4]
########################################
raycaster:
sw    $31, 0x0B44($0)       # spill raycaster's own return address (jal cos/sin below will clobber $31)

# Load base addresses and K constant
lui   $14, 0x0000
ori   $14, $14, 0x05A4      # ARENA_BASE  = 1444 = 0x05A4
lui   $15, 0x0000
ori   $15, $15, 0x0734      # RAYLEN_BASE = 1844 = 0x0734
lui   $16, 0x0000
ori   $16, $16, 0x0934      # CHEIGHT_BASE= 2356 = 0x0934
addi  $17, $0, 32           # K = 32 (real int; FXPU div yields (32<<8)/ray_len = 8192/ray_len)

# Start angle = theta - 64 degrees (in FP: theta - 64*256 = theta - 16384)
addi  $18, $3, -16384

# Wrap start angle into [0, 92160)
lui   $28, 0x0001
ori   $28, $28, 0x6800      # 92160 in $28

slt   $29, $18, $0          # 1 if start_angle < 0
nop
nop
nop
beq   $29, $0, noWrapStart
add   $18, $18, $28         # add 360 deg to bring into range
noWrapStart:

# Also handle case start_angle >= 360 (can happen if theta is very large from wrap imprecision)
slt   $29, $18, $28         # 1 if < 92160
nop
nop
nop
bne   $29, $0, startAngleOk
sub   $18, $18, $28         # subtract 360 deg
startAngleOk:

# ray counter = 128, byte offset = 0
addi  $19, $0, 128
addi  $21, $0, 0

########################################
# RAY LOOP: for each ray i in 0..127
########################################
rayLoop:

# ---- Get ray direction (cos, sin) ----
add   $29, $0, $18
jal   cos
add   $22, $29, $0          # $22 = ray_dir_x = cos(ray_angle), signed FP 24.8

add   $29, $0, $18
jal   sin
add   $23, $29, $0          # $23 = ray_dir_y = sin(ray_angle), signed FP 24.8

# ---- Player cell coordinates ----
# map_x = (x_fp + 1280) >> 8
addi  $28, $1, 1280         # $28 = x_fp + 1280
addi  $29, $0, 8
srlv  $24, $28, $29         # map_x (0..9)

# map_y_from_bottom = (y_fp + 1280) >> 8
addi  $28, $2, 1280
srlv  $25, $28, $29         # map_y_from_bottom (0..9)

# ---- step_x and side_dist_x ----
# Determine x-direction: positive = east, negative = west
slt   $28, $22, $0          # 1 if ray_dir_x < 0
nop
nop
nop
bne   $28, $0, xDirNeg

# ray_dir_x >= 0 (eastward)
addi  $29, $0, 1
sw    $29, 0x0B3C($0)       # step_x = +1
addi  $28, $1, 1280
andi  $28, $28, 0x00FF      # sub-cell x position [0..255]
sub   $28, $11, $28         # frac_x = 256 - pos = dist to east boundary (FP frac)
# ray_dir_x already positive -> abs = $22
j     doneStepX
xDirNeg:
# ray_dir_x < 0 (westward)
addi  $29, $0, -1
sw    $29, 0x0B3C($0)       # step_x = -1
addi  $29, $1, 1280
andi  $28, $29, 0x00FF      # frac_x = pos = dist to west boundary
sub   $22, $0, $22          # $22 = abs(ray_dir_x)
doneStepX:

# side_dist_x = (frac_x << 8) / abs(ray_dir_x)    [FXPU: a=frac, b=dir, f=8]
# = frac_x * 256 / dir_x = FP distance to first x-crossing
div   $26, $28, $22

# delta_dist_x = (256 << 8) / abs(ray_dir_x) = 65536 / dir_x
# = FP distance between consecutive x-crossings
div   $28, $11, $22
sw    $28, 0x0B34($0)       # store delta_dist_x

# ---- step_y and side_dist_y ----
# ray_dir_y > 0 = northward (y_fp increases) -> map_y_from_bottom increases -> step_map_y = +1
# ray_dir_y < 0 = southward (y_fp decreases) -> map_y_from_bottom decreases -> step_map_y = -1
slt   $28, $23, $0          # 1 if ray_dir_y < 0
nop
nop
nop
bne   $28, $0, yDirNeg

# ray_dir_y >= 0 (northward)
addi  $29, $0, 1
sw    $29, 0x0B40($0)       # step_map_y = +1
addi  $28, $2, 1280
andi  $28, $28, 0x00FF      # sub-cell y position
sub   $28, $11, $28         # frac_y = 256 - pos = dist to north cell boundary
j     doneStepY
yDirNeg:
# ray_dir_y < 0 (southward)
addi  $29, $0, -1
sw    $29, 0x0B40($0)       # step_map_y = -1
addi  $29, $2, 1280
andi  $28, $29, 0x00FF      # frac_y = pos = dist to south cell boundary
sub   $23, $0, $23          # $23 = abs(ray_dir_y)
doneStepY:

# side_dist_y = (frac_y << 8) / abs(ray_dir_y)
div   $27, $28, $23
# delta_dist_y = 65536 / abs(ray_dir_y)
div   $28, $11, $23
sw    $28, 0x0B38($0)       # store delta_dist_y

########################################
# DDA INNER LOOP
########################################
ddaLoop:
# Step toward whichever side is closer
slt   $28, $26, $27         # 1 if side_dist_x < side_dist_y
nop
nop
nop
beq   $28, $0, ddaStepY

# ---- X step ----
lw    $28, 0x0B34($0)       # delta_dist_x
nop
nop
nop
add   $26, $26, $28         # side_dist_x += delta_dist_x
lw    $29, 0x0B3C($0)       # step_x
nop
nop
nop
add   $24, $24, $29         # map_x += step_x
j     ddaCheckHit

ddaStepY:
# ---- Y step ----
lw    $28, 0x0B38($0)       # delta_dist_y
nop
nop
nop
add   $27, $27, $28         # side_dist_y += delta_dist_y
lw    $29, 0x0B40($0)       # step_map_y
nop
nop
nop
add   $25, $25, $29         # map_y_from_bottom += step_map_y

ddaCheckHit:
# arena_row = 9 - map_y_from_bottom
addi  $20, $0, 9
sub   $20, $20, $25         # $20 = arena_row (0=north top, 9=south bottom)

# arena_idx = arena_row * 10 + map_x
# Compute arena_row * 10 = (row<<3) + (row<<1) without FXPU
addi  $29, $0, 3
sllv  $28, $20, $29         # $28 = arena_row * 8
addi  $29, $0, 1
sllv  $29, $20, $29         # $29 = arena_row * 2
add   $28, $28, $29         # $28 = arena_row * 10
add   $28, $28, $24         # $28 = arena_row * 10 + map_x = arena_idx
addi  $29, $0, 2
sllv  $28, $28, $29         # $28 = arena_idx * 4 = byte offset
add   $29, $14, $28         # $29 = ARENA_BASE + offset
lw    $28, 0($29)           # $28 = arena cell (0=empty, 1=wall)
nop
nop
nop
beq   $28, $0, ddaLoop      # not a wall; keep stepping

########################################
# HIT: determine ray length from last side
########################################
# After stepping: whichever side_dist is smaller is the side we JUST stepped into.
# (We incremented it, so it may now be larger than the other; use the one we stepped.)
# If we just stepped X: side_dist_x was incremented last, so we use side_dist_x.
# If we just stepped Y: side_dist_y was incremented.
# Detect: if side_dist_x <= side_dist_y, we stepped X (side_dist_x was the smaller before step).
slt   $28, $27, $26         # 1 if side_dist_y < side_dist_x  -> last step was Y
nop
nop
nop
bne   $28, $0, hitYSide

# Hit on X side: ray_len = side_dist_x - delta_dist_x
hitXSide:
lw    $29, 0x0B34($0)       # delta_dist_x
nop
nop
nop
sub   $28, $26, $29         # ray_len = side_dist_x - delta_dist_x
j     storeLen

hitYSide:
# Hit on Y side: ray_len = side_dist_y - delta_dist_y
lw    $29, 0x0B38($0)       # delta_dist_y
nop
nop
nop
sub   $28, $27, $29         # ray_len = side_dist_y - delta_dist_y

storeLen:
# Clamp minimum ray_len to 1 to avoid huge heights (div by tiny value)
slt   $29, $28, $11         # 1 if ray_len < 256 (< 1.0 unit)
nop
nop
nop
beq   $29, $0, noClampLen
addi  $28, $11, 0           # clamp to 256 (= 1.0 unit min)
noClampLen:

# Store ray length
add   $29, $15, $21
sw    $28, 0($29)           # RAYLEN_BASE[i] = ray_len (FP 24.8)

# Column height = (K << 8) / ray_len   [FXPU: a=K=32, b=ray_len, f=8]
# = (32 * 256) / ray_len = 8192 / ray_len   (integer result)
div   $29, $17, $28         # $29 = height (integer)

# Clamp height to [0, 64]
addi  $28, $0, 64
slt   $28, $28, $29         # 1 if 64 < height
nop
nop
nop
beq   $28, $0, noClampH
addi  $29, $0, 64
noClampH:

# Store column height
add   $28, $16, $21
sw    $29, 0($28)           # CHEIGHT_BASE[i] = height (integer)

########################################
# Advance to next ray
########################################
# ray_angle += 1 degree (FP: +256)
add   $18, $18, $11

# Wrap ray_angle if >= 360 deg (FP: >= 92160)
lui   $28, 0x0001
ori   $28, $28, 0x6800      # 92160
slt   $29, $18, $28
nop
nop
nop
bne   $29, $0, noWrapRay
sub   $18, $18, $28
noWrapRay:

addi  $21, $21, 4           # next result slot (byte offset += 4)
addi  $19, $19, -1          # ray counter--
nop
nop
nop
bne   $19, $0, rayLoop      # loop if more rays remain

# All 128 rays done; restore return address and return to main loop
lw    $31, 0x0B44($0)       # restore raycaster's return address
nop
nop
nop
jr    $31