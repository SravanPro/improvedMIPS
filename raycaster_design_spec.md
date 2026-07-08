# DDA Raycaster on Custom Pipelined MIPS — Design Specification

> **Note for the implementing instance:** alongside this document, the user will
> provide (1) the combined full RTL source (all Verilog modules + testbenches)
> and (2) the current `.asm` file. This document is the specification layer —
> read it together with those source files, which remain the ground truth for
> exact code state.

## 1. Project Context

This is a custom 5-stage pipelined MIPS processor implemented in Verilog, part of a
larger FPGA system (analog input handler → processor → renderer → SPI display).
The goal of this phase is to finish an in-progress DDA-based raycaster: a MIPS
assembly program computes 128 ray lengths against a 10×10 arena stored in DMEM,
converts them to column heights, and a Verilog renderer draws those columns to an
8192-bit (128×64) framebuffer sent out over SPI.

### 1.1 Architecture facts

- **MMIO**: byte-addressed at `0xFFFFFF00+n`. Each address returns a 32-bit
  all-0s/all-1s word replicated from a single status bit (see `memory.v`'s
  combinational read block). Not normal word-addressed memory.
- **DMEM**: `memory.v`, flip-flop array (`reg [7:0] mem[]`), synchronous write /
  combinational read, big-endian word layout. `memorySizeInBytes = 3000`.
- **FXPU**: fixed-point unit (`fxpu.v`), format **24.8**, `.f` parameter set to
  `5'd8` in `pipeline.v`.
  - `mul rd, rs, rt` → `rd = (rs * rt) >> 8`
  - `div rd, rs, rt` → `rd = (rs << 8) / rt`
- **IMEM**: packed binary instructions, built with existing assembler.
  `instructionMemSizeInBytes = 4096` (current; increase if program overflows).
- **Assembler**: existing assembler converts assembly to IMEM binary; encoding is
  out of scope — write assembly with labels, let the assembler handle PCs.
- **Pipeline hazards** (follow as-is):
  - `jr`: insert 3 NOPs before it (resolves in ID, no forwarding into ID).
  - `beq`/`bne`: insert 3 NOPs if any preceding instruction writes a register the
    branch reads. Mandatory for `lw` → branch on loaded value.
  - `j`/`jal`: no NOPs needed — flush handled automatically.
  - `mul`/`div`: FXPU auto-stalls entire pipeline; no manual NOPs needed.
- **JAL/JR**: both correct for single-level (non-nested) calls. No stack needed.
  No RTL fix required.
- **Arena cells**: ISA has no `lb`/`sb` — arena is **word-packed** (4 bytes/cell,
  value in LSB), loaded with `lw`.

### 1.2 Register Map (raycaster.asm)

| Reg | Meaning |
|---|---|
| `$1` | player x (FP 24.8) |
| `$2` | player y (FP 24.8) |
| `$3` | player angle θ (FP 24.8) |
| `$4`–`$9` | mmi0–mmi5 (x inc/dec, y inc/dec, θ inc/dec) |
| `$10` | coord step resolution = 26 |
| `$11` | angle resolution = 256 (1° in FP) |
| `$12` | +1280 (+5 units in FP) |
| `$13` | −1280 (−5 units in FP) |
| `$14` | ARENA_BASE = 0x05A4 (set in raycaster) |
| `$15` | (free) |
| `$16` | CHEIGHT_BASE = 0x0734 (set in raycaster) |
| `$17` | K = 32 (height scale constant, set in raycaster) |
| `$18` | current ray angle (per-ray, FP 24.8) |
| `$19` | ray counter (128 down to 1) |
| `$20` | scratch / arena_row temp in DDA |
| `$21` | ray byte offset (0, 4, 8, …, 508) |
| `$22` | ray_dir_x (abs value, FP 24.8) |
| `$23` | ray_dir_y (abs value, FP 24.8) |
| `$24` | map_x (cell col, integer 0–9) |
| `$25` | map_y_from_bottom (cell row from south, integer 0–9) |
| `$26` | side_dist_x (FP 24.8) |
| `$27` | side_dist_y (FP 24.8) |
| `$28` | temp |
| `$29` | temp / trig I/O |
| `$30` | MMIO base (0xFFFFFF00) |
| `$31` | return address |

### 1.3 Fixed-point constants (24.8)

- Coord step: 0.1 unit → 26
- Angle step: 1° → 256
- Arena bounds: ±5 units → ±1280
- 1.0 unit → 256
- 360° → 92160 (0x16800)

## 2. Decisions

| # | Topic | Decision |
|---|---|---|
| 1 | FXPU scale | `.f(5'd8)` set in `pipeline.v` ✓ **DONE** |
| 2 | DMEM size | `memorySizeInBytes = 3000` ✓ **DONE** |
| 3 | IMEM size | 4096B current; increase if assembler output overflows |
| 4 | Rays / FOV | 128 rays, 128° FOV, 1°/ray, 1:1 ray-to-pixel mapping |
| 5 | Register allocation | Freely reallocated; jal/jr calling convention preserved |
| 6 | Fisheye correction | Not applied — raw Euclidean ray length used |
| 7 | Column height formula | `h = (K<<8) / ray_len_fp` via FXPU div; K=32 (real int) stored in `$17` |
| 8 | Arena packing | **Word-packed** (4 bytes/cell, value in LSB, `lw` to read). No `lb` in ISA. |
| 9 | Player start angle | θ anticlockwise from east; 0°=E, 90°=N, 180°=W, 270°=S |
| 10 | Player start position | x=0 (FP=0), y=−128 (FP=−0.5 units), θ=270° (FP=69120) — open area, facing south |
| 11 | Movement collision | Outer-wall clamping only; no internal wall collision |
| 12 | Register spilling | DDA scratch (delta_dist, step) spills to 4 DMEM words at 0x0B34 |
| 13 | Column height storage | Plain integers, one 32-bit word per column (128 words = 512B) |
| 14 | Renderer / colHeights | Old `raycastRenderer.v` and `colHeights` wire scrapped. New renderer uses `h0..h127` named ports. ✓ **DONE** |

## 3. Consolidated Implementation Specification

### 3.1 Arena Map

10×10 grid, `1` = wall, `0` = empty. **Word-packed in DMEM** (4 bytes per cell,
value in LSB). Arena index for cell `(arena_row, map_x)`:

```
byte_offset = ((9 - map_y_from_bottom) * 10 + map_x) * 4
DMEM address = ARENA_BASE + byte_offset
```

Grid (row 0 = north/top, row 9 = south/bottom):

```
1 1 1 1 1 1 1 1 1 1   ← row 0 (north wall)
1 0 0 0 0 0 0 0 0 1
1 0 0 0 0 0 0 0 0 1
1 0 0 1 1 1 0 0 0 1   ← internal wall segment (row 3, cols 3–5)
1 0 0 0 0 0 0 0 0 1
1 0 0 0 0 0 0 0 0 1
1 0 0 0 0 0 0 0 0 1
1 0 0 0 0 0 0 0 0 1
1 0 0 0 0 0 0 0 0 1
1 1 1 1 1 1 1 1 1 1   ← row 9 (south wall)
```

Player starts near row 5, col 5 (x=0, y=−0.5 units), facing south (θ=270°).

### 3.2 DMEM Layout

| Region | Start | End | Size | Notes |
|---|---|---|---|---|
| Sine LUT | 0x0000 | 0x05A3 | 1444 B | 361 × 4 bytes, 0°–360°, FP 24.8 |
| Arena map | 0x05A4 | 0x0733 | 400 B | 100 × 4 bytes, word-packed |
| Column heights | 0x0734 | 0x0933 | 512 B | 128 × 4 bytes, integer |
| DDA scratch | 0x0934 | 0x0943 | 16 B | 4 × 4 bytes (see §3.5) |
| Ra spill | 0x0944 | 0x0947 | 4 B | Raycaster return address |
| **Total** | | | **2376 B** | `memorySizeInBytes = 2376` |

### 3.3 DDA Scratch Layout (base 0x0934)

| Offset | Contents |
|---|---|
| +0x00 | delta_dist_x (FP 24.8) |
| +0x04 | delta_dist_y (FP 24.8) |
| +0x08 | step_x (+1=east, −1=west) |
| +0x0C | step_map_y (+1=north/map_y increases, −1=south) |

### 3.4 Player / Ray Model

- FP format: 24.8 throughout.
- θ: 0°=east, anticlockwise. LUT indexed in integer degrees.
- FOV: 128°, 128 rays, 1°/ray. Start angle = θ − 64°. Center ray = θ.
- Ray length → height: `h = (32 << 8) / ray_len_fp` (FXPU div, f=8). K=32 in `$17`.
- No fisheye correction.
- Height clamped to [0, 64]; min ray_len clamped to 256 (1.0 unit).
- Div by zero safe: FXPU returns 0xFFFFFFFF for zero divisor (side never hit first).

### 3.5 Coordinate Mapping

```
map_x             = (x_fp + 1280) >> 8        [0=west, 9=east]
map_y_from_bottom = (y_fp + 1280) >> 8        [0=south, 9=north]
arena_row         = 9 - map_y_from_bottom      [0=north, 9=south]
```

Step directions:
- ray_dir_x ≥ 0 → step_x = +1, frac_x = 256 − ((x_fp+1280) & 0xFF)
- ray_dir_x < 0 → step_x = −1, frac_x = (x_fp+1280) & 0xFF; negate dir for abs
- ray_dir_y ≥ 0 (north) → step_map_y = +1, frac_y = 256 − ((y_fp+1280) & 0xFF)
- ray_dir_y < 0 (south) → step_map_y = −1, frac_y = (y_fp+1280) & 0xFF; negate dir for abs

FXPU division formulas (all with f=8):
- `side_dist = div(frac_fp, abs_dir_fp)` → `(frac<<8)/dir` = FP distance to first crossing
- `delta_dist = div(256, abs_dir_fp)` → `65536/dir` = FP distance between crossings
- `height = div(32, ray_len_fp)` → `8192/ray_len` = integer column height

### 3.6 Function-call Convention

- Single-level calls only (`jal` → `jr $31`), no stack.
- sin/cos: input `$29` (FP 24.8 degrees), output `$29` (FP 24.8 value).
- raycaster: called with `jal raycaster` each main loop iteration; returns via `jr $31`.
- No nested calls anywhere.

### 3.7 RTL Interface

- **`pipeline.v`**: exposes `h0..h127` (128 × 32-bit outputs), each a combinational
  tap on `DMEM.mem[CHEIGHT_BASE + i*4 .. +3]` (big-endian). `colHeights` removed.
  FXPU `.f(5'd8)`.
- **`raycastRenderer.v`**: new module, same name. Inputs `h0..h127`, output `fb [8191:0]`.
  Renders one column per clock cycle, loops forever. Framebuffer bit index: `Y*128 + X`.
- **`parent.v`**: wires `h0..h127` from `PIPELINE` to both `RAYCAST_RENDERER` and
  exposes them on module boundary. Old `colHeights [4095:0]` wire removed.
- **`memory.v`**: `memorySizeInBytes = 3000`. Arena initializer at 0x05A4 (word-packed).

### 3.8 Expected Behavior / Acceptance Check

At startup (player at x=0, y=−0.5, θ=270°, facing south):
- Center column (ray 64) hits the south outer wall directly; should be **tallest**.
- Heights decrease toward left/right edges of screen.
- Deviations near the internal wall segment (row 3, cols 3–5) are expected.

Sanity numbers: south wall at y=−5, player at y=−0.5, distance ≈ 4.5 units (FP≈1152).
Expected center height ≈ 8192/1152 ≈ 7. Increase K (`$17`) to taste.

### 3.9 Open Items / TODOs

- [ ] Run assembler on `raycaster.asm` → update `instructionMem.v` binary.
- [ ] Increase `instructionMemSizeInBytes` if assembled program exceeds 4096 bytes.
- [ ] Tune K (`$17` in assembly, currently 32) after first simulation.
- [ ] Verify `DMEM.mem[...]` hierarchical path resolves correctly in simulator.
- [x] TB1 is the active testbench (`tb0.v` not used). Column heights dumped to `improvedMIPS.srcs/sim_1/new/column_heights.txt`.

## 4. Files Delivered This Session

| File | Status | Key changes |
|---|---|---|
| `raycaster.asm` | New | Full assembly: init + movement + raycaster + sin/cos |
| `memory.v` | Updated | `memorySizeInBytes=3000`; arena map initializer added at 0x05A4 |
| `pipeline.v` | Updated | `colHeights` removed; `h0..h127` outputs added; FXPU `f=8` |
| `raycastRenderer.v` | Replaced | New implementation with `h0..h127` individual input ports |
| `parent.v` | Updated | Wires `h0..h127` between pipeline and renderer |
| `tb0.v` | Ignored | Not used; TB1 is active testbench |

---
*This document supersedes the previous version. All source files are the ground truth.*
