# improvedMIPS — Claude Code Onboarding

## Project Overview

This is a custom **5-stage pipelined MIPS processor** (IF → ID → EX → MEM → WB) implemented in Verilog as a Vivado project. The processor runs a **DDA-based raycaster** program that renders a 128-column first-person view of a 10×10 arena onto a 128×64 SSD1306 OLED display via SPI. The system includes analog joystick/button input, hardware fixed-point multiply/divide (FXPU), and a dedicated raycast renderer module.

**Target FPGA:** Vivado synthesis → real hardware (exact FPGA part TBD — check `improvedMIPS.xpr`).

---

## Repository Structure

```
C:\misc\improvedMIPS\
├── improvedMIPS.srcs/
│   ├── sources_1/new/      # All 33 Verilog source modules (RTL)
│   └── sim_1/new/           # Testbenches (TB1.v is active; tb0.v is unused)
├── improvedMIPS.xpr         # Vivado project file
├── improvedMIPS.runs/       # Synthesis/implementation runs
├── improvedMIPS.sim/        # Simulation outputs (XSim)
├── improvedMIPS.cache/      # Vivado cache
├── improvedMIPS.hw/         # Hardware manager files
├── pyFiles/                 # Python assembler toolchain
│   ├── asm.py               # MIPS assembler: .asm → instruction memory binary
│   ├── input.txt             # Assembly source input (paste asmcode.asm here)
│   ├── output.txt            # Assembled binary output (paste into instructionMem.v)
│   ├── reference.c           # C reference for the raycaster algorithm
│   └── assembler.exe         # Pre-compiled assembler binary
├── cFiles/
│   ├── lutGenerator/         # C program to generate sine LUT initializers
│   │   ├── sineLUT.c         # Full 1440-entry sine LUT generator (0.25° resolution)
│   │   └── sineLUTReduced.c  # 361-entry sine LUT generator (1° resolution) — current
│   └── verilogFilesCopier/   # C utility to concatenate Verilog sources
│       └── copyVerilog.c
├── asmcode.asm              # Current raycaster MIPS assembly source
├── pipeline_design_report.md # Exhaustive 26-module RTL design audit (read first!)
├── raycaster_design_spec.md  # Raycaster specification with register map and DMEM layout
├── README.md                 # Same content as pipeline_design_report.md
├── infoToKnow.txt            # Quick hazard NOP rules reference
├── nopsInfo.txt              # Detailed NOP rules with reasoning
├── onboarding.txt            # Workflow reference (how to assemble, where files are)
├── specs/                    # (empty — for future specs)
└── .gitignore                # Ignores Vivado build artifacts, .venv
```

---

## Key Reference Documents (read these first)

| File | Purpose |
|---|---|
| `pipeline_design_report.md` | **Primary reference.** Full RTL audit: every module, every stage, every stall/flush signal, FXPU mechanics, all known limitations. 26 modules documented. |
| `raycaster_design_spec.md` | Assembly-level raycaster spec: register map, DMEM layout, DDA algorithm, coordinate system, FXPU division formulas. |
| `infoToKnow.txt` / `nopsInfo.txt` | Quick vs detailed NOP requirements for hazard avoidance. |
| `onboarding.txt` | Workflow cheat-sheet for building and running. |

---

## Architecture: The Complete Module Graph

### Top-level hierarchy
```
parent.v
├── tff.v                    → clock divider flip-flop
├── analogTranslator.v       → decodes color-coded analog input pins → direction signals
├── movementDivider.v        → divides raw movement signals (debounce/speed control)
├── pipeline.v               → the 5-stage MIPS CPU (see below)
├── segment.v                → 7-segment display decoder (debug: shows r1, r2)
├── raycastRenderer.v        → converts 128 column heights → 8192-bit framebuffer
└── spi.v                    → SSD1306 OLED SPI driver FSM (reads fb[8191:0])
```

### Pipeline internal modules (all instantiated in `pipeline.v`)

| Module | File | Role |
|---|---|---|
| `pc` | pc.v | Program counter register with stall input |
| `adder` (×2) | adder.v | PC+4 and branch target (NPC + imm<<2) |
| `instructionMem` | instructionMem.v | 4096-byte instruction ROM, combinational read, preloaded with assembled program |
| `if_id` | if_id.v | IF/ID pipeline register; stall + flush |
| `mainControl` | mainControl.v | Opcode decoder → all main control signals |
| `jrControl` | jrControl.v | Detects `jr` in ID |
| `jTypeAddressProcessor` | jTypeAddressProcessor.v | J-type target: `{NPC[31:28], IR[25:0], 2'b00}` |
| `signExtend` / `zeroExtend` | signExtend.v / zeroExtend.v | 16→32 bit immediate extension |
| `sext_or_zext_control` | sext_or_zext_control.v | Sign vs zero-extension select (zero for andi/ori/xori/lui) |
| `regFile` | regFile.v | 32×32 register file; combinational write-forwarding, dual read ports, debug taps r1/r2 |
| `id_ex` | id_ex.v | ID/EX pipeline register (widest); carries operands + all control + IsMul/IsDiv |
| `hazardDetectionUnit` | hazardDetectionUnit.v | Classic load-use hazard detector |
| `forwardingUnit` | forwardingUnit.v | EX/MEM and MEM/WB → EX-stage forwarding mux selects |
| `mux4` (×2) | mux4.v | EX-stage forwarding muxes (A and B operands) |
| `mux2` (×many) | mux2.v | Generic 2:1 mux, reused everywhere |
| `aluControl` | aluControl.v | Secondary decode: aluOp + funct → ALU opcode |
| `alu` | alu6.v | Combinational ALU: add/sub/and/or/nor/xor/slt/sll/srl/sra/lui/inc/dec/seq + zero flag |
| `shiftLeft2` | shiftLeft2.v | imm << 2 for branch target |
| `fxpu` | fxpu.v | Fixed-point unit wrapper (start/busy/done/result handshake) |
| `mul_booth_radix4` | mul_booth_radix4.v | 16-cycle radix-4 Booth multiplier |
| `div_nonrestoring` | div_nonrestoring.v | 32-cycle non-restoring divider |
| `ex_mem` | ex_mem.v | EX/MEM pipeline register; stall + flush |
| `memory` | memory.v | 3000-byte DMEM: registered read, synchronous write; preloaded with sine LUT + arena map + scratch |
| `mem_wb` | mem_wb.v | MEM/WB pipeline register; stall-only |
| `spi.v` | spi.v | NOT instantiated in pipeline — wired in `parent.v` |

**Note:** `alu` is defined in `alu6.v`, not `alu.v`. The pipeline instantiates it as `alu ALU(...)`.

---

## Fixed-Point Format (24.8)

- **Fractional bits (f):** 8 (hardwired as `5'd8` in pipeline.v)
- **Format:** 24 integer bits + 8 fractional bits in a 32-bit signed word
- **FXPU mul:** `rd = (rs * rt) >> 8` (radix-4 Booth, 16 cycles)
- **FXPU div:** `rd = (rs << 8) / rt` (non-restoring, 32 cycles)
- **Key constants:**
  - 1.0 unit = 256 (0x100)
  - 1° = 256
  - 360° = 92160 (0x16800)
  - Arena bounds: ±5 units = ±1280
  - Coord step: 0.1 unit = 26

---

## Hazard / NOP Rules (CRITICAL for assembly programming)

These stem from the pipeline's structural limitations. Read `pipeline_design_report.md` §5 for the full analysis.

| Instruction | NOPs Needed | Rule |
|---|---|---|
| `jr $31` | **3 NOPs before** | Resolves in ID with zero forwarding into the register-file read; any producer still in EX/MEM/WB is invisible |
| `beq` / `bne` | **3 NOPs before** if any preceding instruction writes a register the branch reads | Conservative rule from `infoToKnow.txt`. Branches resolve in MEM via EX-stage forwarding; `lw` immediately before a branch is a hard (unrecoverable) failure |
| `j` / `jal` | **0 NOPs** | Pure immediate target, no register read; flush handled automatically |
| `lw` → consumer | **3 NOPs after** | Load data has 2-cycle latency (registered DMEM read + stall cycle); wait until value reaches MEM/WB |
| `mul` / `div` | **0 manual NOPs** | FXPU auto-stalls the entire pipeline for 17/33 cycles; handled in hardware |

**The assembler (`asm.py`) automatically inserts 3 NOPs before `jr`/`beq`/`bne` when it detects the preceding 3 instructions write a register those instructions read.** You can write assembly without manual hazard NOPs — the assembler handles it. However, the assembler does NOT insert NOPs after `lw` — those must be handled manually in source code.

---

## Instruction Set (MIPS subset)

| Type | Instructions |
|---|---|
| **R-type** | `add`, `sub`, `and`, `or`, `slt`, `nor`, `xor`, `sll`, `srl`, `sra`, `sllv`, `srlv`, `srav`, `jr`, `mul`, `div` |
| **I-type** | `lw`, `sw`, `beq`, `bne`, `addi`, `andi`, `ori`, `xori`, `slti`, `lui` |
| **J-type** | `j`, `jal` |
| **Pseudo** | `nop` (encodes as `sll $0, $0, 0` → 0x00000000) |

**Notable omissions from standard MIPS:** no `lb`/`sb` (byte loads/stores) → arena cells are word-packed and read via `lw`. No `mult`/`mflo` — hardware `mul`/`div` use the FXPU and encode as standard R-type with `funct` fields.

---

## DMEM Layout (3000 bytes)

| Region | Start | End | Size | Contents |
|---|---|---|---|---|
| Sine LUT | 0x0000 | 0x05A3 | 1444 B | 361 × 4 bytes, sin(0°..360°) in FP 24.8 |
| Arena map | 0x05A4 | 0x0733 | 400 B | 100 × 4 bytes, 10×10 cells, word-packed, 1=wall 0=empty |
| Column heights | 0x0734 | 0x0933 | 512 B | 128 × 4 bytes, integer heights [0..64] |
| DDA scratch | 0x0934 | 0x0943 | 16 B | 4 words: delta_dist_x, delta_dist_y, step_x, step_map_y |
| Ra spill | 0x0944 | 0x0947 | 4 B | Raycaster return address spill |

---

## MMIO (Memory-Mapped IO)

- **Base address:** `0xFFFFFF00` (detected via `address[31:8] == 24'hFFFFFF` in memory.v)
- **Bit layout** in `parent.v`: `memMappedIO = {gameRst, erase, draw, down, up, left, right, ...}`
- **Reading:** Returns a 32-bit all-0s or all-1s word replicated from a single status bit
- **Writing:** Not supported (read-only input port)
- **Assembly access:** `lw $rt, offset($30)` where `$30 = 0xFFFFFF00`:
  - `0($30)` = right, `1($30)` = left, `2($30)` = up, `3($30)` = down, `4($30)` = rotate right, `5($30)` = rotate left

---

## Coordinate System

- **θ = 0°:** east (+x), **anticlockwise**: 90°=north, 180°=west, 270°=south
- **Player start:** x=0 (FP: 0), y=−0.5 (FP: −128), θ=270° facing south
- **map_x:** `(x_fp + 1280) >> 8` → 0=west wall, 9=east wall
- **map_y_from_bottom:** `(y_fp + 1280) >> 8` → 0=south wall, 9=north wall
- **arena_row:** `9 - map_y_from_bottom` → 0=north/top, 9=south/bottom
- **FOV:** 128° across 128 rays = 1°/ray, 1:1 ray-to-pixel mapping
- **Column height:** `h = (K << 8) / ray_len` where K=32 → `8192 / ray_len`, clamped to [0, 64]

---

## Registers (Raycaster Convention)

| Reg | Variable | Notes |
|---|---|---|
| `$1` | player_x | FP 24.8 |
| `$2` | player_y | FP 24.8 |
| `$3` | player_θ | FP 24.8, 0–92160 |
| `$4`–`$9` | mmi0–mmi5 | MMIO input states |
| `$10` | coord_step = 26 | 0.1 unit in FP |
| `$11` | angle_step = 256 | 1° in FP |
| `$12` | +1280 | +5 units |
| `$13` | −1280 | −5 units |
| `$14` | ARENA_BASE = 0x05A4 | |
| `$15` | (free) | |
| `$16` | CHEIGHT_BASE = 0x0734 | |
| `$17` | K = 32 | height scale constant |
| `$18` | ray_angle | per-ray, FP |
| `$19` | ray_counter | 128→1 |
| `$20` | arena_row temp | DDA scratch |
| `$21` | ray_byte_offset | 0, 4, 8, … 508 |
| `$22` | abs(ray_dir_x) | FP 24.8 |
| `$23` | abs(ray_dir_y) | FP 24.8 |
| `$24` | map_x | integer 0–9 |
| `$25` | map_y_from_bottom | integer 0–9 |
| `$26` | side_dist_x | FP 24.8 |
| `$27` | side_dist_y | FP 24.8 |
| `$28`–`$29` | temp / trig I/O | |
| `$30` | MMIO_BASE = 0xFFFFFF00 | |
| `$31` | return address | |

---

## Key Pipeline Design Details

### Stall/Flush Signal Map (from `pipeline_design_report.md` §7)

| Register | `stall` driven by | `flush` driven by |
|---|---|---|
| `pc` | `~hdu_PCWrite \| fxpu_stall_id \| dmem_stall` | *(none)* |
| `if_id` | `~hdu_IF_IDWrite \| fxpu_stall_id \| dmem_stall` | `id_jump \| id_jal \| id_jr \| mem_PCSrc` |
| `id_ex` | `fxpu_stall_id \| dmem_stall` | `mem_PCSrc \| hdu_ID_EXStall` |
| `ex_mem` | `fxpu_stall_all \| dmem_stall` | `mem_PCSrc` |
| `mem_wb` | `fxpu_stall_all \| dmem_stall` | *(none)* |

### Three stall sources (OR'd together):
1. **HDU (load-use):** freezes PC + IF/ID, bubbles ID/EX for 1 cycle
2. **FXPU (mul/div busy):** freezes entire pipeline for 17 (mul) or 33 (div) cycles
3. **DMEM stall (registered read):** 1-cycle stall on every `lw` to accommodate synchronous DMEM read

### FXPU integration:
- `fxpu_active` flip-flop tracks in-flight operation (set on `fxpu_start`, cleared on `fxpu_done`)
- `fxpu_stall_id = fxpu_busy | fxpu_start` → freezes front end
- `fxpu_stall_all = fxpu_busy` → freezes back end
- `ex_aluResult_final` mux selects FXPU result over ALU result based on `id_ex_IsMul | id_ex_IsDiv`

### Forwarding:
- Two independent priority-encoded muxes (RS→A, RT→B)
- Priority: EX/MEM (`10`) > MEM/WB (`01`) > no forwarding (`00`)
- Injection point: **EX stage only** (ALU/FXPU operand muxes)
- Correctly excludes `$0` as a destination

### Branch handling:
- `mem_PCSrc = (BranchEq & Zero) | (BranchNe & ~Zero)` — resolves in MEM
- Single `mem_PCSrc` wire fans out to flush `if_id`, `id_ex`, `ex_mem` AND selects PC mux
- Squashes exactly 2 wrongly-fetched instructions on a taken branch

---

## Workflow: How to Modify and Test

### 1. Edit the assembly program
Edit `asmcode.asm` (or write new assembly). Follow the hazard NOP rules in `infoToKnow.txt` — or let the assembler insert them automatically for `jr`/`beq`/`bne`.

### 2. Assemble
```bash
# Copy assembly into input.txt, then:
cd C:\misc\improvedMIPS\pyFiles
python asm.py input.txt output.txt
```
Alternatively, paste `asmcode.asm` content directly into `input.txt`.

### 3. Update instruction memory
Copy the assembled output from `output.txt` and paste it into `instructionMem.v`'s `load_program` task body (replacing the existing `mem[...]` lines between the `////////////////////` markers). The assembled output is Verilog-compatible mem initializer lines.

### 4. Simulate (Icarus Verilog / XSim)
- **Active testbench:** `TB1.v` (not `tb0.v`)
- **Simulation flow:** TB1 instantiates `parent`, which instantiates everything
- **Clock:** 10ns period (100 MHz) — `always #5 clock = ~clock`
- TB1 dumps column heights to `column_heights.txt` at t=1ms and t≈3.4ms (full path: `improvedMIPS.srcs/sim_1/new/column_heights.txt`)
- **iverilog quick-check:** elaborate all source files (excluding `spi.v` which needs the full parent hierarchy for its `fb` input) and run a short simulation

### 5. Synthesize (Vivado)
Open `improvedMIPS.xpr` in Vivado → Run Synthesis → Run Implementation → Generate Bitstream.

### 6. C tools
- **Sine LUT generator:** `cFiles/lutGenerator/sineLUTReduced.exe` — generates the 361-entry sine LUT initializers pasted into `memory.v`'s `initial` block. Source: `sineLUTReduced.c`.
- **Verilog copier:** `cFiles/verilogFilesCopier/copyVerilog.exe` — concatenates all Verilog source files. Source: `copyVerilog.c`.

---

## Known Limitations (from `pipeline_design_report.md` §9)

1. **JR has no forwarding path** — requires 3 NOPs separation from any producer (assembler handles this)
2. **Branches resolve in MEM** — `lw` immediately before a branch is unrecoverable; needs 3 NOPs
3. **HDU only detects load-use** — no JR or branch-specific hazard detection
4. **Forwarding is EX-stage only** — nothing forwards into ID; `mux4[11]` is dead code
5. **FXPU stalls entire pipeline** — no scoreboarding; 17/33 cycle full-pipeline freeze per mul/div
6. **DMEM uses unaligned byte-array accesses** — 4 overlapping byte reads per 32-bit word complicates clean BRAM inference
7. **h0..h127 taps use hierarchical references** (`DMEM.mem[...]`) — simulation-valid but need real dual-port BRAM ports for synthesis
8. **`spi.v` is wired in `parent.v`** — correct, but the hierarchical `fb` tap path should be verified end-to-end
9. **`mem_PCSrc` is high-fan-out** — single wire does 4 jobs; careful when modifying branch timing

---

## Source File Locations

- **RTL Verilog:** `C:\misc\improvedMIPS\improvedMIPS.srcs\sources_1\new\`
- **Testbenches:** `C:\misc\improvedMIPS\improvedMIPS.srcs\sim_1\new\`
- **Assembler:** `C:\misc\improvedMIPS\pyFiles\asm.py`
- **Active testbench:** `TB1.v` (tb0.v is unused/legacy)
- **Vivado project:** `C:\misc\improvedMIPS\improvedMIPS.xpr`

---

## Coding Conventions

- **Verilog:** `timescale 1ns / 1ps` throughout. Mixed use of `assign` and `always @(*)` for combinational logic. Pipeline registers use explicit `_stall`/`_flush` ports. Big-endian memory layout.
- **Assembly:** MIPS syntax with `$` registers, labels with `:`, `#` or `//` comments. Labels and instruction mnemonics are case-insensitive. The assembler supports hex (`0x...`) and decimal immediates with optional negation.
- **Naming:** Module instances in `pipeline.v` use UPPER_SNAKE_CASE (e.g., `PC_ADDER`, `FORWARD_MUX_A`).
