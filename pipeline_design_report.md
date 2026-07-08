# MIPS-Style 5-Stage Pipeline — Design State Report

**Scope of this report:** a full audit of the RTL as uploaded (26 files), centered on `pipeline.v` as the
top-level integration point. Part 1 documents the design as it stands today — architecture, every module,
every interconnection, and the working of the control/hazard/forward/FXPU/memory subsystems, with explicit
call-outs of every limitation found in the code. Part 2 is a placeholder for future work.

**Module inventory check:** all 26 modules instantiated in `pipeline.v` were found among the uploaded files
(`alu` is defined in `alu6.v`, not a file named `alu.v` — no functional gap, just a naming mismatch worth
knowing about). One uploaded file, `spi.v`, is **not instantiated anywhere in `pipeline.v`**. It's a
complete, self-contained SSD1306-style OLED SPI driver FSM that reads a `[8191:0] fb` framebuffer input —
it must be wired in at a higher-level top module that hasn't been shared, presumably built from the `h0..h127`
column-height taps (or some rasterized version of them) plus other renderer logic. Treat it as parked
off to the side of this report; nothing below depends on it.

---

# PART 1 — Current Design State

## 1. High-Level Architecture

This is a classic 5-stage MIPS pipeline (IF → ID → EX → MEM → WB) with the textbook hazard machinery
(forwarding + stalling + flushing), extended in two custom directions:

1. **A multi-cycle fixed-point unit (FXPU)** bolted onto the EX stage for hardware `mul`/`div`, using
   24.8 fixed-point (8 fractional bits) math via a radix-4 Booth multiplier and a non-restoring divider.
2. **An application-specific data memory** (`memory.v`) pre-loaded at synthesis/elaboration time with a
   sine LUT, a packed arena map, and scratch regions for a DDA (Digital Differential Analyzer) raycaster —
   i.e., this CPU's actual job is to run a small raycasting renderer program (see `instructionMem.v`'s
   embedded program: cos/sin table calls, a `raycaster` routine, DDA stepping, wall-height clamping) and
   expose the resulting column heights and framebuffer to display hardware (`spi.v`, and the `h0..h127`
   taps in `pipeline.v`).

The pipeline itself is a fairly faithful Hennessy/Patterson-style implementation: five pipeline registers
(`if_id`, `id_ex`, `ex_mem`, `mem_wb`), a hazard detection unit that stalls on load-use hazards, a forwarding
unit that forwards into the EX stage ALU inputs only, and branch resolution deferred to the MEM stage using
a flush signal that squashes IF/ID and ID/EX. Jumps resolve one stage earlier (ID) and flush only IF/ID.

## 2. Module Inventory and Role of Each

| Module | File | Role |
|---|---|---|
| `pipeline` | pipeline.v | Top-level integration; wires every stage together, plus DDA column-height taps and raw register taps (`r1`, `r2`) for observability |
| `pc` | pc.v | Program counter register; single stall input gates update |
| `adder` | adder.v | Generic parameterized adder; used for `PC+4` and for the branch target (`NPC + (imm<<2)`) |
| `instructionMem` | instructionMem.v | 4096-byte instruction ROM, combinationally read (`{mem[pc],mem[pc+1],mem[pc+2],mem[pc+3]}`), preloaded via a `load_program` task with the full raycaster/trig program |
| `if_id` | if_id.v | IF/ID pipeline register: NPC (PC+4) and IR (raw instruction); supports stall (hold) and flush (zero) |
| `mainControl` | mainControl.v | Primary opcode decoder → regDst, aluSrc, memToReg, regWrite, memRead, memWrite, branchEq, branchNe, jump, jal, aluOp |
| `jrControl` | jrControl.v | Detects `jr` (`opcode==0, funct==001000`) combinationally in ID |
| `jTypeAddressProcessor` | jTypeAddressProcessor.v | Builds the J-type target address: `{NPC[31:28], IR[25:0], 2'b00}` |
| `signExtend` / `zeroExtend` | signExtend.v / zeroExtend.v | 16→32 bit immediate extension, both computed in parallel |
| `sext_or_zext_control` | sext_or_zext_control.v | Picks sign- vs zero-extension based on `aluOp` (zero-extend for `andi/ori/xori/lui`) |
| `regFile` | regFile.v | 32×32 register file; **combinational write-forwarding built into the read ports themselves** (see §9); dual read ports plus always-on debug taps `r1`=$1, `r2`=$2 |
| `id_ex` | id_ex.v | ID/EX pipeline register — the widest one; carries operands, immediate, all control signals, IsMul/IsDiv; supports stall (hold) and flush (zero) |
| `hazardDetectionUnit` | hazardDetectionUnit.v | Classic load-use hazard detector; drives `PCWrite`, `IF_IDWrite`, `ID_EXStall` |
| `forwardingUnit` | forwardingUnit.v | EX/MEM and MEM/WB → EX-stage forwarding mux selects, for RS and RT independently |
| `mux4` (×2) | mux4.v | The two EX-stage forwarding muxes (A and B operand) |
| `mux2` (many) | mux2.v | Generic 2:1 mux, reused everywhere (RegDst, ALUSrc, immediate select, JAL overrides, branch/jump PC select, MemToReg, JR override) |
| `aluControl` | aluControl.v | Secondary decode: `aluOp` (+ `funct` for R-type) → 4-bit ALU opcode |
| `alu` | alu6.v | Combinational ALU: add/sub/and/or/nor/xor/slt/sll/srl/sra/lui-shift/inc/dec/seq, plus `zero` flag |
| `shiftLeft2` | shiftLeft2.v | `imm << 2` for branch target math |
| `fxpu` | fxpu.v | Wraps the multiplier and divider behind one start/busy/done/result interface, with fixed-point scaling |
| `mul_booth_radix4` | mul_booth_radix4.v | 16-cycle radix-4 Booth multiplier, 64-bit product |
| `div_nonrestoring` | div_nonrestoring.v | 32-cycle non-restoring divider, operates on a pre-shifted 64-bit dividend |
| `ex_mem` | ex_mem.v | EX/MEM pipeline register; supports stall (hold, used during FXPU busy) and flush (zero, on taken branch) |
| `memory` | memory.v | 3000-byte data memory: **combinational (asynchronous) read, synchronous write** (see §9); pre-loaded with sine LUT + arena map; memory-mapped IO window at the top of the address space |
| `mem_wb` | mem_wb.v | MEM/WB pipeline register; stall-only (held during FXPU busy), no flush needed this late |
| `spi.v` | spi.v | **Not wired into `pipeline.v`.** Standalone SSD1306 OLED SPI driver + page-addressing FSM, reads a `fb` framebuffer input |

## 3. Stage-by-Stage Walkthrough

### IF (Instruction Fetch)
`pc` holds the current PC. `PC_ADDER` computes `pc_plus4`. `IMEM` (`instructionMem`) is a purely
combinational ROM read — `pcVal` in, `instruction` out on the same cycle, no clock edge involved in the
read path at all. The next-PC mux chain is: `branchMuxOut` (PC+4 or branch target, selected by `mem_PCSrc`)
→ `jumpMuxOut` (that or the J-type target, selected by `id_jump | id_jal`) → `pc_next` (that or `id_rd1`,
selected by `id_jr` — i.e., the JR target is read straight out of the register file in ID and injected into
the PC path with top mux priority).

`pc`'s stall input is `~hdu_PCWrite | fxpu_stall_id` — the PC freezes on a load-use hazard *or* whenever the
FXPU is starting/busy.

### ID (Instruction Decode)
`if_id_IR` is decoded combinationally: opcode/rs/rt/rd/funct/imm16 are all plain bit-slices of the latched
instruction. `mainControl` produces the full control-signal bundle from the opcode; `jrControl` produces
`id_jr` from opcode+funct. `regFile` is read at `rn1=id_RS`, `rn2=id_RT`, producing `id_rd1`/`id_rd2` —
these are the values used both for JR's target and as the A/B operands going into `id_ex`. Sign/zero
extension of the 16-bit immediate happens here, gated by `sext_or_zext_control`.

`hazardDetectionUnit` looks one stage ahead (at `id_ex_MemRead`, `id_ex_RT`) against the currently-decoding
`if_id_RS`/`if_id_RT` and, on a match, freezes `PCWrite`/`IF_IDWrite` and asserts `ID_EXStall` (which forces
a bubble into `id_ex` next cycle via `id_ex_flush`).

### EX (Execute)
`forwardingUnit` compares `id_ex_RS`/`id_ex_RT` against `ex_mem_RD` and `mem_wb_RD` (qualified by their
respective `RegWrite` and non-zero-destination checks) and drives two independent 2-bit selects into
`mux4` A/B forwarding muxes. Selected inputs: `00`=id_ex's own latched value (no hazard), `01`=WB-stage
write-back data, `10`=EX/MEM stage ALU result, `11`=hardwired zero (unused/dead code path — see §5).

`ALUSRC_MUX` picks between the (possibly-forwarded) B operand and the immediate. `aluControl` + `alu`
do the actual ALU op. In parallel, the FXPU is kicked off (`fxpu_start = (id_ex_IsMul | id_ex_IsDiv) &
~fxpu_active`) using the *forwarded* A/B operands — so mul/div results ARE be able to receive
forwarded data correctly, same as the ALU. `ex_aluResult_final` muxes between the plain ALU result and
the FXPU result based on `id_ex_IsMul | id_ex_IsDiv`. The branch target address is computed here
(`shiftLeft2` + `BRANCH_ADDER`) even though the branch decision itself doesn't resolve until MEM.

### MEM (Memory)
`mem_PCSrc = (BranchEq & Zero) | (BranchNe & ~Zero)` — this is where branches actually resolve, one full
stage later than a "textbook" single-cycle datapath would resolve them, because the ALU's zero flag from
the EX stage has to first be latched into `ex_mem` before this stage can look at it. This is the single
biggest structural fact driving the branch-hazard rules in §5.

`memory` (DMEM) is addressed by `ex_mem_AluOut` (computed address), written with `ex_mem_B` (forwarded
store data, latched a stage earlier), and read combinationally (see §9 — this is the crux of the sync/async
discussion you asked about).

### WB (Write-Back)
`MEMTOREG_MUX` picks ALU result vs. loaded memory data; `JAL_MEMTOREG_MUX` overrides that with the saved
NPC if the instruction is `jal` (implementing `$ra = PC+4`). The final `wb_writeData_final` and
`wb_regDest`/`wb_regWrite` feed straight back into `regFile`'s write port, same cycle, and — critically —
`regFile`'s *read* ports are combinationally forwarded from that very same write (see §9), so ID-stage reads
in the *same cycle* as a WB-stage write see the new value without needing the pipeline forwarding network at
all. This is a legitimate, common trick, but its scope is exactly "same-cycle WB write, ID read" — it does
**not** help EX-stage operands, which is why the explicit forwarding network in §4 still exists.

## 4. Forwarding Unit — Detailed Behavior and Limitations

`forwardingUnit.v` is a pure combinational block, two independent priority-encoded `always @(*)` blocks
(one for RS→A, one for RT→B):

```
if (ex_mem_RegWrite && ex_mem_RD != 0 && ex_mem_RD == id_ex_RS) forwardA = 2'b10;  // EX/MEM has priority
else if (mem_wb_RegWrite && mem_wb_RD != 0 && mem_wb_RD == id_ex_RS) forwardA = 2'b01;
else forwardA = 2'b00;
```

This is textbook EX-hazard forwarding, correctly prioritizing the *closer* hazard (EX/MEM, i.e., the
instruction one cycle ahead) over the *farther* one (MEM/WB), and correctly excluding `$0` as a destination.

**What it covers well:** the standard back-to-back ALU-ALU and load-then-use-two-instructions-later cases,
for both integer ALU ops and (thanks to the FXPU being fed the same `forwardMuxA_out`/`forwardMuxB_out`
signals) `mul`/`div` operands.

**What it structurally cannot do — and why:**

- **It only has one injection point: the EX-stage ALU/FXPU operand muxes.** There is no forwarding path
  into the ID stage. Any instruction that consumes a register value *in ID* — which today means only `jr`,
  since branches don't read registers directly (they rely on the EX-stage ALU's zero flag) — gets zero
  benefit from this unit. This is exactly the root cause of the JR hazard in §5.
- **The `2'b11` select case is dead code.** `mux4`'s `s==2'b11` input is hardwired to `32'b0` and
  `forwardingUnit` never drives `2'b11` — there's no third forwarding source (e.g., a would-be EX/EX
  same-cycle path) wired up. Harmless today, but it means if a third hazard source is ever added, the mux
  already has a slot but the encode/select logic doesn't use it.
- **No forwarding for the store-data operand's *destination* check against `ex_mem`/`mem_wb`'s `RD` when
  that operand is itself the store address computation** — this actually *is* covered, since `ex_aluB`/
  `forwardMuxB_out` also feeds `ALUSRC_MUX`→ the address adder and `ex_mem_B_in` (store data) is the same
  forwarded B value. So `sw` correctly gets forwarded data for both its address-base register and its
  store-value register. No gap here, noted only because it's a common place designs get this wrong and
  this one doesn't.
- **No load-to-load-with-immediate-offset special case** — not needed; the HDU's stall already handles the
  one real load-use gap (see §5), and forwarding correctly picks up the loaded value the cycle after that.

## 5. Hazard Detection Unit — Detailed Behavior, Stall Mechanism, and the Branch/Jump/JR Rules

`hazardDetectionUnit.v` implements exactly one hazard check — the classic load-use hazard:

```
if (id_ex_MemRead && ((id_ex_RT == if_id_RS) || (id_ex_RT == if_id_RT)))
    PCWrite = 0; IF_IDWrite = 0; ID_EXStall = 1;
```

i.e., if the instruction currently sitting in EX is a `lw` and the instruction currently decoding in ID
reads the same register as that `lw`'s destination, freeze the PC and IF/ID (so the same instruction
re-decodes next cycle) and force a bubble into ID/EX (`id_ex_flush = mem_PCSrc | hdu_ID_EXStall` — note this
OR's together with the branch-flush condition, so the same flush port serves double duty). This buys exactly
one cycle: after the stall, the load's result is one stage further along (now sitting in `ex_mem`), which is
exactly where the forwarding unit's `10` (EX/MEM) path can catch it as the following instruction enters EX.

That's the **entire** hazard-detection logic in this design — there is no hazard checking for branches or
for JR here at all. All of the JR/branch NOP requirements you asked about are a direct consequence of *where
in the pipeline each of these three control-flow instructions resolves*, cross-referenced against where the
forwarding network's only injection point is (EX stage) and where the HDU's only check is (load-use, ID vs.
EX). Walking through each:

### `jr` — needs 3 NOPs / clear separation before it
`id_jr` is computed combinationally in ID from `if_id_IR`, and the JR target is `id_rd1` — read directly out
of `regFile`'s combinational read port using `if_id_IR[25:21]` as the address, **with no forwarding applied
to it whatsoever.** `regFile`'s own internal same-cycle WB-forwarding (§9) is the *only* protection this read
gets, and that only covers the specific case where the producing instruction is *currently in WB* the same
cycle `jr` is in ID. If the producing instruction is still in EX, or still in MEM (i.e., its result hasn't
reached `mem_wb`/`regFile`'s write port yet), `jr`'s ID-stage read sees the *stale* register value, and
because `id_rd1` is muxed straight onto `pc_next` with top priority the same cycle, there is no way to
correct this after the fact — the wrong address is already latched into `pc` on the next clock edge. Since
a value can be sitting in EX, MEM, or WB relative to `jr`'s ID stage (three cycles of "in flight" before it's
safely retired into the register file and combinationally visible), the rule is **3 instructions/NOPs of
separation** between a write to `jr`'s source register and the `jr` itself.

### `beq`/`bne` — needs 2 NOPs minimum, 3 to be safe; `lw`-immediately-before is a hard failure
Branches don't read the register file directly at decode; they ride the normal `id_ex`→EX pipeline path
like any ALU instruction, get their operands through the *normal* forwarding network, and resolve using
`ex_mem_Zero` (the latched EX-stage ALU zero flag) in the MEM stage. Because they go through the standard
EX-stage forwarding, most producer/consumer distances are covered by `forwardingUnit` exactly the way a
normal ALU instruction would be — this is why 2 NOPs is usually enough (by the time the branch reaches EX,
a producer that started 2 instructions earlier is sitting in `ex_mem` or `mem_wb`, both of which are valid
forwarding sources). The **hard failure case** is a `lw` *directly* before a branch that reads the loaded
register: the HDU detects this as a standard load-use hazard and stalls one cycle — but that stall only
buys the same one cycle it always buys, sufficient for a normal ALU consumer entering EX, but the branch's
consumption of the value also happens in EX (same place, same timing as any other instruction), so
**the loaded data still isn't valid yet when the branch's EX cycle happens** — there is no *second* stall or
extra forwarding path to bridge this specific two-cycle-load-latency-vs-one-cycle-stall gap. This is exactly
why 3 NOPs (rather than 2) is the safe rule: it removes any ambiguity around load-latency interactions the
HDU/forwarding combination doesn't fully close.

### `j`/`jal` — 0 NOPs needed
`id_jump`/`id_jal` are pure opcode decodes off `if_id_IR`, and the jump target (`jTypeAddressProcessor`) is
built entirely from immediate instruction bits and the latched NPC — no register operand is read at all, so
there is no producer/consumer hazard to create in the first place. The one architectural side effect of
taking a jump is the instruction fetched the cycle after the jump instruction (before the target is known) —
this is squashed automatically by `if_id_flush = id_jump | id_jal | id_jr | mem_PCSrc`, which zeroes
`if_id_NPC_out`/`if_id_IR_out` (effectively injecting a bubble) the same cycle the jump is detected. Note
this flush line also fires for `id_jr` and for `mem_PCSrc` (taken branch) — all four control-flow-changing
conditions share the same one-bubble-into-IF/ID squash mechanism.

**Summary table**

| Instruction | Resolves in | Reads register operands via | NOP rule | Root cause |
|---|---|---|---|---|
| `jr` | ID (same cycle) | Raw `regFile` read, zero forwarding | 3 NOPs | No forwarding path into ID; only same-cycle WB→ID collapse in `regFile` protects against the most recent case |
| `beq`/`bne` | MEM | Normal EX-stage forwarding | 2 NOPs (3 to be safe); `lw` immediately before is a hard failure | Forwarding covers most cases; HDU's one-cycle stall isn't enough to close the `lw`-immediately-before-branch gap |
| `j`/`jal` | ID (same cycle) | None — no register read | 0 NOPs | Target is pure immediate/PC math; one auto-squashed fetch bubble via `if_id_flush` |

## 6. FXPU (Fixed-Point Unit) — Structure and Working

`fxpu.v` is a thin coordination wrapper around two independent multi-cycle datapaths, exposing a single
start/busy/done/result handshake to the pipeline:

- **Multiply path** (`mul_booth_radix4.v`): a genuine radix-4 (2-bits-per-cycle) Booth multiplier. It
  recodes overlapping 3-bit windows of the multiplier (`b`) using the standard Booth radix-4 table
  (window→{0, ±1×, ±2×}), accumulates the sign-extended, appropriately-shifted partial product into a
  65-bit accumulator over **16 cycles** (32 bits ÷ 2 bits/cycle), and asserts `done` after `count==15`.
  Produces a full 64-bit product.
- **Divide path** (`div_nonrestoring.v`): a classic non-restoring divide-by-repeated-subtract-or-add
  algorithm over **32 cycles** (one bit of quotient per cycle), operating on sign-magnitude-converted
  operands (dividend/divisor absolute values are computed at `start`, the result sign is recorded
  separately via `neg_result = dividend_sign ^ divisor_sign` and reapplied at the end), with explicit
  special-casing for a zero divisor (`quotient = 32'hFFFFFFFF`) and a zero dividend (`quotient = 0`).
- **Fixed-point scaling** happens entirely in `fxpu.v`, at the boundary of each datapath: the divider's
  64-bit dividend is pre-shifted left by `f` (fractional bits, here **8**, giving 24.8 format) *before*
  the raw integer division, effectively computing `(a << f) / b`; the multiplier's raw 64-bit product is
  *post*-shifted right (arithmetically, sign-preserving) by the same latched `f`, effectively computing
  `(a * b) >> f`. `f` and `isDiv` are both latched into `f_latched`/`isDiv_latched` on the `start` pulse
  specifically so that a mid-operation change to the `f` input (e.g. from a parameter or future dynamic
  source) can't corrupt an in-flight operation — a defensive design choice, notable because `f` is
  currently hardwired to a constant (`5'd8`) at the pipeline level, so this protection is currently inert
  but is the right call if `f` ever becomes instruction-selectable.

**Pipeline-side integration and stalling.** `pipeline.v` tracks FXPU occupancy with one extra flip-flop,
`fxpu_active`, set on `fxpu_start` and cleared on `fxpu_done`. Two derived stall signals fan out from this:

- `fxpu_stall_id = fxpu_busy | fxpu_start` — freezes the *entire front end*: the `pc` and `if_id` both stall
  on this (via their existing stall inputs, OR'd with the HDU's own stall condition), so no new instruction
  advances into or through ID while a mul/div is in flight.
- `fxpu_stall_all = fxpu_busy` — freezes `ex_mem` and `mem_wb` (their `stall` inputs hold their entire
  latched contents unchanged), so whatever was already past the FXPU's stage stays frozen in place too,
  and `id_ex` is stalled by the wider `fxpu_stall_id`.

Net effect: a `mul`/`div` in `id_ex` freezes essentially the *whole pipeline* for its duration (17 or 33
cycles including the start cycle) — every stage holds, nothing retires, nothing new fetches. This is simple
and correct (no risk of a second mul/div issuing while one is in flight, no risk of stale data anywhere) but
it is a full-pipeline stall, not a scoreboarded or structural-hazard-only stall — the EX/MEM/WB stages sit
idle even though they have no actual dependency on the in-flight multiply/divide. This is a throughput cost
worth flagging as a limitation (see §8), especially given the program running on this CPU (`instructionMem.v`)
calls `mul`/`div` fairly often (sin/cos table lookups scaled by radius, DDA step-size divisions, etc.).

`ex_aluResult_final` mux (in `pipeline.v`) selects the FXPU's `result` over the plain ALU's `result` whenever
`id_ex_IsMul | id_ex_IsDiv` — so from EX/MEM's perspective downstream, a mul/div instruction just looks like
any other ALU instruction with a (delayed) result; there's no separate result path or separate destination
register handling needed further down the pipeline.

## 7. Stall / Flush Mechanism — Full Signal Map

Every pipeline register in this design exposes exactly two control inputs — `*_stall` (hold current
contents) and `*_flush` (zero all fields, i.e., insert a bubble) — and the top-level wiring in `pipeline.v`
composes the various hazard sources onto these two ports per register:

| Register | `stall` driven by | `flush` driven by | Effect |
|---|---|---|---|
| `pc` | `~hdu_PCWrite \| fxpu_stall_id` | *(none — pc has no flush port, reset only)* | Freezes PC on load-use hazard or FXPU busy/starting |
| `if_id` | `~hdu_IF_IDWrite \| fxpu_stall_id` | `id_jump \| id_jal \| id_jr \| mem_PCSrc` | Freezes on load-use/FXPU hazard; squashes (bubbles) on any taken control-flow change |
| `id_ex` | `fxpu_stall_id` | `mem_PCSrc \| hdu_ID_EXStall` | Freezes only for FXPU; bubbles on taken branch **or** on a load-use hazard (this is how the HDU actually injects its stall bubble) |
| `ex_mem` | `fxpu_stall_all` | `mem_PCSrc` | Freezes while FXPU busy; bubbles on taken branch (squashes the wrongly-fetched instruction once it reaches this register) |
| `mem_wb` | `fxpu_stall_all` | *(none)* | Freezes while FXPU busy; no flush needed since nothing past MEM needs squashing on a branch — it's already committed |

Two important structural notes:

1. **The HDU's stall is implemented as a flush, not a stall, on `id_ex`.** `hdu_ID_EXStall` ORs into
   `id_ex_flush`, not `id_ex_stall`. This is functionally correct for a load-use bubble (you want a genuine
   NOP inserted into EX, not the old contents held), but it means `id_ex`'s `stall` input is used *only*
   for the FXPU case in this design — worth knowing if you're tracing signal names later and expecting the
   HDU's stall to show up on the `stall` port.
2. **`mem_PCSrc` is the single most overloaded control signal in the design** — it simultaneously flushes
   `if_id` (squash the wrongly-fetched instruction after a taken branch), flushes `id_ex` (squash the
   instruction that was decoding when the branch resolved), and drives `ex_mem_flush` (squash whatever was
   computed in EX that same cycle, if anything reached there speculatively) and selects the branch target
   into the PC mux chain. This is architecturally correct for a MEM-stage-resolved branch (you need to
   squash exactly the 2 instructions fetched after the branch, which is what flushing both `if_id` and
   `id_ex` on the same cycle accomplishes), but it's worth being aware that a single wire fans out to four
   separate jobs — any future change to branch resolution timing needs to be very deliberate about touching
   this signal.

## 8. Synchronous vs. Asynchronous Memory — DMEM, and Why It Blocks BRAM Inference

**Instruction memory (`instructionMem.v`)** is combinational/asynchronous read only (`assign instruction =
{mem[pcVal], ...}`) — a ROM, never written after elaboration, so this one is generally fine for BRAM
inference in most toolchains (a read-only combinational array initialized at elaboration is a very common,
well-supported BRAM/ROM inference pattern), though some toolchains still prefer a registered read even for
ROMs to get a "true" block-RAM primitive rather than distributed/LUT-based memory.

**Data memory (`memory.v`) is the one that actually matters here, and it does not fit a standard BRAM
inference template:**

```verilog
// ---- combinational read ----
always @(*) begin
    if (memRead) begin
        if (address[31:8] != 24'hFFFFFF)
            readData = {mem[address], mem[address+1], mem[address+2], mem[address+3]};
        else
            readData = (address[7:0] < ioWidth) ? {32{memMappedIO[address[7:0]]}} : 32'b0;
    end else readData = 32'b0;
end

// ---- synchronous write ----
always @(posedge clock or posedge reset) begin
    if (!reset && memWrite && address[31:8] != 24'hFFFFFF) begin
        mem[address]   <= writeData[31:24];
        ... 
    end
end
```

This is a **mixed asynchronous-read / synchronous-write** memory. The write side (registered, edge-triggered)
is exactly what BRAM wants. The read side (`always @(*)`, driven straight off the current `address` input
with zero register stages in between) is exactly what BRAM *cannot* do natively — every real block-RAM
primitive (Xilinx `RAMB18/RAMB36`, Altera/Intel M9K/M20K, Lattice, etc.) has a **registered read port**: you
present an address on a clock edge, and the data appears after that same edge (or, for "output-registered"
modes, one edge later) — there is no path in the primitive's hardware for the read data to combinationally
follow the address within the same cycle the way this Verilog demands. Additionally, `mem` here is declared
as a byte-addressable, byte-wide array (`reg [7:0] mem [memorySizeInBytes-1:0]`) accessed via four
overlapping unaligned byte reads per 32-bit word (`mem[address]`, `mem[address+1]`, etc.) — this specific
access pattern (four separate reads at runtime-computed adjacent addresses, concatenated combinationally) is
itself unusual for BRAM inference even before the sync/async issue, since most inference rules expect a
single aligned address feeding a single word-wide port; most synthesis tools will very likely fall back to
distributed RAM / LUTRAM / registers for this whole array rather than inferring true block RAM, which is
wasteful of fabric resources and slower to route at scale on an FPGA, even though it will simulate correctly
and even work post-synthesis (just not efficiently, and not scalably to a larger memory).

There's a secondary complication layered on top of this, worth flagging even though it's outside the
`memory.v` module itself: **the `h0..h127` column-height taps in `pipeline.v` use hierarchical references
straight into `DMEM.mem[...]`** (`DMEM.mem[CHEIGHT_BASE + 0]`, etc.). This is simulation-valid (Verilog
allows hierarchical references into a `reg` array for read purposes) and, per the comments already in the
file, is only claimed to be "synthesis-ready if DMEM is implemented as a dual-port BRAM" — i.e., this
tap mechanism itself is implicitly *assuming* a synchronous, properly-inferred BRAM with a second read port
behind the scenes; as written today (single async-read array, no second port), these taps would need to
become real dual-port BRAM read-port instantiations rather than raw hierarchical peeks once DMEM is made
synthesizable, which is a second, related piece of follow-up work beyond just fixing the primary
read/write path.

### Two ways to make the DMEM read synchronous

You mentioned you already know the two options — for completeness, here's what each concretely means for
this specific RTL:

**Option A — stall the pipeline for 1 cycle on every memory access.**
Keep the 5 stages as they are; add one cycle of latency to every `lw`. Concretely: register `mem_readData`
(add a `posedge clock` flop between the array read and the value that reaches `mem_wb`), and have the
MEM stage assert a new stall (freezing everything before it — `pc`, `if_id`, `id_ex`, and `ex_mem` itself)
for one cycle on any `MemRead`, mirroring exactly the mechanism the HDU already uses for load-use hazards,
just triggered unconditionally on every load rather than only on a detected hazard. This is the smaller,
more surgical change (new small stall-generation block + wiring one more stall condition into the four
upstream registers' existing stall ports) but it costs one cycle of throughput on **every** load
instruction, not just hazardous ones, and it also somewhat changes the forwarding picture — a value coming
out of a now-2-cycle-latency load reaches `ex_mem` a cycle later than before, so the existing EX/MEM (`10`)
forwarding path would actually miss it and it would need to be picked up one cycle later by the MEM/WB
(`01`) path instead, which should already work given how the forwarding priority is coded but is worth
re-verifying instruction-by-instruction once this is in.

**Option B — split MEM into two half-stages (MEM1/MEM2), making it a 6-stage pipeline.**
Add a new pipeline register between the current address-generation part of MEM and the rest (data
return/write-back selection), so cycle 1 of the new MEM does the read *address* presentation and the array
lookup lands in a register at the end of that cycle, and cycle 2 of the new MEM (structurally identical to
today's WB-adjacent logic) consumes the now-registered `readData`. This is the architecturally "cleaner"
long-term fix — no wasted stall cycles, one instruction genuinely completes every cycle in steady state,
matching how real BRAM-backed pipelined CPUs are actually built — but it's the larger change: a new pipeline
register (with its own stall/flush ports, wired consistently with the pattern in §7), branch-resolution
timing pushed out by one more stage (since `mem_PCSrc` currently depends on `ex_mem`'s outputs — you'd need
to decide whether branch resolution stays tied to the *first* new MEM half-stage or moves to the second),
and the forwarding unit gaining a third potential source stage to check against (today it only compares
against `ex_mem` and `mem_wb`; with MEM split in two, there's a new intermediate stage's outputs that may
also need to be a forwarding source depending on where branch/ALU results are latched relative to the split).

**Decision: Option A (one-cycle stall per load) — implemented.** Details in §8a below.

## 8a. Implemented: Synchronous DMEM Read via a One-Cycle Load Stall

Two files changed: `memory.v` and `pipeline.v`. No other module was touched — the forwarding unit,
hazard detection unit, and pipeline-register modules (`if_id`/`id_ex`/`ex_mem`/`mem_wb`) are all unmodified;
this was implemented purely as a new stall condition composed onto the stall ports those registers already
exposed.

### `memory.v` — read port is now registered

The old combinational block:
```verilog
always @(*) begin
    if (memRead) readData = ...;
    else         readData = 32'b0;
end
```
is now a clocked block:
```verilog
always @(posedge clock or posedge reset) begin
    if (reset)          readData <= 32'b0;
    else if (memRead)   readData <= ...;   // same address logic, now sampled at posedge
    else                readData <= 32'b0;
end
```
This is now a direct match for real BRAM read-port timing: the address is sampled on a clock edge, and
`readData` is valid starting the cycle *after* that edge — one cycle of latency where there used to be
none. The unaligned-byte-access pattern (`mem[address]`, `mem[address+1]`, ...) is unchanged and still a
separate concern from §9's limitation list (still worth revisiting for clean BRAM inference), but the
sync/async timing issue itself — the actual blocker — is resolved.

### `pipeline.v` — new one-cycle stall, `dmem_wait` / `dmem_stall`

A new single-bit register, `dmem_wait`, and a combinational `dmem_stall` wire were added, following the
exact same idiom the design already uses for `fxpu_active`/`fxpu_busy`:

```verilog
reg  dmem_wait;
wire dmem_stall = ex_mem_MemRead & ~dmem_wait;

always @(posedge clock or posedge reset) begin
    if (reset) dmem_wait <= 1'b0;
    else       dmem_wait <= dmem_stall;
end
```

**Why a state bit is needed at all (unlike the HDU's stateless load-use check):** the HDU's hazard
condition clears itself for free, because the *hazardous* instruction naturally advances out of `id_ex`
after one stall cycle, changing the signal the HDU is watching. Here, the opposite is required — `ex_mem`
must be *held in place* (frozen) for the extra wait cycle so the load's address stays stable across the
clock edge that latches DMEM's now-registered read, and so its control info (`RD`, `RegWrite`, `MemToReg`,
...) stays correctly paired with the data once it arrives. Because we're deliberately freezing the very
signal (`ex_mem_MemRead`) that the stall condition is based on, that condition would stay true forever
without a second bit tracking "have we already paid this cycle." `dmem_wait` is exactly that bit: `dmem_stall`
fires for exactly one cycle per load (the cycle it first lands in `ex_mem`), then `dmem_wait` goes high,
which forces `dmem_stall` low the next cycle regardless of `ex_mem_MemRead` still being asserted — allowing
the now-valid data to be captured and the pipeline to advance — and `dmem_wait` immediately falls back to 0
in the same step, ready for the next load.

**Wiring — `dmem_stall` was OR'd onto every existing stall port**, alongside the pipeline's existing FXPU
stall signals:

| Register | Stall expression (new term in bold) |
|---|---|
| `pc` | `~hdu_PCWrite \| fxpu_stall_id \| `**`dmem_stall`** |
| `if_id` | `~hdu_IF_IDWrite \| fxpu_stall_id \| `**`dmem_stall`** |
| `id_ex` | `fxpu_stall_id \| `**`dmem_stall`** (flush input unchanged — this is a *stall*, not a bubble; the instruction behind the load must simply wait, not be squashed) |
| `ex_mem` | `fxpu_stall_all \| `**`dmem_stall`** |
| `mem_wb` | `fxpu_stall_all \| `**`dmem_stall`** |

`mem_wb` stalling too is important and easy to miss: during the wait cycle itself, DMEM's registered
`readData` is *not yet valid* (it becomes valid only after the edge the stall cycle spans), so `mem_wb`
must be held during that cycle to avoid latching stale/garbage data — it's only safe to let `mem_wb` advance
on the following cycle, once `dmem_stall` has dropped and the real data is present. This mirrors exactly why
`ex_mem` already needed to hold — both must freeze together during the wait cycle and release together the
cycle after.

**Net effect / cost:** every `lw` now costs exactly one extra cycle in the pipeline (previously zero,
since the read was combinational and same-cycle). Non-memory instructions and `sw` (write is still purely
synchronous, unaffected) are untouched. This was verified with `iverilog`: the full design (all 26 modules,
excluding the unwired `spi.v`) elaborates cleanly, and a smoke-test simulation running the embedded raycaster
program for several thousand ns shows no `X` propagation and produces sane register values, confirming the
stall doesn't stick or double-fire.

**Known follow-on effect, not yet separately re-verified instruction-by-instruction:** a loaded value now
reaches `mem_wb` one cycle later relative to the instructions around it than before. The existing
forwarding-unit priority encoding (EX/MEM checked before MEM/WB) should still resolve this correctly — a
consumer that used to catch the load via the `10` (EX/MEM) path may now need to catch it via the `01`
(MEM/WB) path one cycle later instead — but this is exactly the kind of interaction flagged as worth
re-checking in the original §8 write-up, and is a good candidate for the next round of hazard-timing
verification (see Part 2).

## 9. Consolidated List of Limitations

- **JR has no forwarding path** — reads `regFile` combinationally in ID with zero coverage from the
  forwarding unit; requires 3 NOPs of separation from any producer (§5).
- **Branches resolve in MEM, one stage later than their register operands are actually needed for the
  decision** — mostly saved by ordinary EX-stage forwarding, but `lw` immediately before a branch is an
  unrecoverable one-cycle-short case even with the HDU's stall (§5).
- **The HDU only detects one hazard shape** — load-use, EX-vs-ID. It does not, and structurally cannot
  from its inputs alone, detect or protect the JR-reads-in-ID case, nor add any extra stall for the
  branch-after-load case beyond the generic one-cycle load-use stall.
- **The forwarding unit has exactly one injection point (EX-stage operand muxes)** — nothing forwards into
  ID, and the `2'b11`/hardwired-zero fourth forwarding-mux input is unused dead logic today.
- **FXPU stalls the *entire* pipeline for the full multiply/divide latency (17/33 cycles)**, even though
  only the EX stage (and anything data-dependent on it) actually needs to wait — a scoreboard or
  non-blocking issue scheme could let independent instructions behind a mul/div continue, but none exists
  today.
- ~~**DMEM's read port is combinational (asynchronous)**, incompatible with standard block-RAM inference~~
  **RESOLVED (§8a):** DMEM's read is now registered/synchronous, via a one-cycle pipeline stall
  (`dmem_wait`/`dmem_stall`) on every load. Still outstanding: the read is built from four overlapping
  unaligned byte-array accesses rather than a single aligned word-wide port read, which still complicates
  clean BRAM inference even with correct timing now in place — a separate follow-up item.
- **The `h0..h127` column-height taps rely on Verilog hierarchical references into `DMEM.mem`**, which are
  simulation-valid but, per the code's own comments, only synthesis-viable under the assumption DMEM becomes
  a proper dual-port BRAM — i.e., this is coupled to, and blocked on, the same synchronous-read rework
  discussed in §8.
- **`spi.v` is present in the file set but not instantiated by `pipeline.v`** — whatever top-level module
  wires the CPU to the OLED display isn't part of this upload set, so its correctness with respect to the
  `h0..h127`/framebuffer path can't be verified from what's here.
- **`mem_PCSrc` is a single wire doing four jobs** (flush `if_id`, flush `id_ex`, flush `ex_mem`, select the
  PC mux) — correct today, but a high-fan-out signal to keep a very close eye on during the MEM-stage split
  discussed in §8, since Option B changes exactly which stage this signal is computed in and which
  registers it needs to keep flushing.

---

# PART 2 — Future Plans

- [x] Decide and implement synchronous DMEM read — **Option A (one-cycle stall per load) implemented**,
      see §8a. `memory.v` read port is now registered; `pipeline.v` gained `dmem_wait`/`dmem_stall` wired
      into all five pipeline-register stall ports.
- [ ] Re-verify forwarding-unit coverage instruction-by-instruction now that a load's data lands in
      `mem_wb` one cycle later than before (flagged at the end of §8a) — confirm the MEM/WB (`01`) forwarding
      path correctly catches cases that used to be caught one cycle earlier by the EX/MEM (`10`) path.
- [ ] Address the remaining DMEM synthesis wrinkle: four overlapping unaligned byte-array accesses per
      32-bit word, rather than a single aligned word-wide port — worth resolving even now that the
      sync/async timing itself is fixed, for clean BRAM inference.
- [ ] Convert `h0..h127` hierarchical DMEM taps into real (dual-port BRAM) read-port instantiations, now
      that DMEM's primary read port is synchronous — the taps' own comments already assumed this dependency.
- [ ] Locate/author the top-level module that wires `spi.v` and the framebuffer to this pipeline
- [ ] (Open items to be added as they're decided)
