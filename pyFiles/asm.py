#!/usr/bin/env python3
import sys, re

R = {f"${i}": i for i in range(32)}
ALIASES = {"$zero":0,"$at":1,"$v0":2,"$v1":3,"$a0":4,"$a1":5,"$a2":6,"$a3":7,
"$t0":8,"$t1":9,"$t2":10,"$t3":11,"$t4":12,"$t5":13,"$t6":14,"$t7":15,
"$s0":16,"$s1":17,"$s2":18,"$s3":19,"$s4":20,"$s5":21,"$s6":22,"$s7":23,
"$t8":24,"$t9":25,"$k0":26,"$k1":27,"$gp":28,"$sp":29,"$fp":30,"$ra":31}
for i in range(32): ALIASES[f"${i}"]=i

def reg(tok):
    tok = tok.strip().rstrip(',')
    if tok not in ALIASES:
        raise ValueError(f"bad register: {tok}")
    return ALIASES[tok]

R_FUNCT = {
    "add":0b100000,"sub":0b100010,"and":0b100100,"or":0b100101,
    "slt":0b101010,"nor":0b100111,"xor":0b100110,
    "sll":0b000000,"srl":0b000010,"sra":0b000011,
    "sllv":0b000100,"srlv":0b000110,"srav":0b000111,
    "jr":0b001000,"mul":0b011000,"div":0b011010,
}
I_OP = {
    "lw":0b100011,"sw":0b101011,"beq":0b000100,"bne":0b000101,
    "addi":0b001000,"andi":0b001100,"ori":0b001101,"xori":0b001110,
    "slti":0b001010,"lui":0b001111,
}
J_OP = {"j":0b000010,"jal":0b000011}

RTYPE_RD_RS_RT = {"add","sub","and","or","slt","nor","xor"}
RTYPE_RD_RT_SHAMT = {"sll","srl","sra"}
RTYPE_RD_RT_RS = {"sllv","srlv","srav"}
RTYPE_RD_RS_RT_MULDIV = {"mul","div"}

def sign16(v):
    v &= 0xFFFF
    return v

def parse_imm(tok):
    tok = tok.strip()
    neg = False
    if tok.startswith('-'):
        neg = True; tok = tok[1:]
    if tok.lower().startswith('0x'):
        v = int(tok,16)
    else:
        v = int(tok,10)
    if neg: v = -v
    return v

def strip_comment(line):
    for c in ('#','//'):
        idx = line.find(c)
        if idx != -1:
            line = line[:idx]
    return line

def tokenize(line):
    line = line.replace(',', ' , ')
    line = re.sub(r'\(', ' ( ', line)
    line = re.sub(r'\)', ' ) ', line)
    return line.split()

DEST_REG_IDX = {
    # mnemonic -> index of dest register token, or 'jal' handled separately
    "add":0,"sub":0,"and":0,"or":0,"slt":0,"nor":0,"xor":0,"mul":0,"div":0,
    "sll":0,"srl":0,"sra":0,"sllv":0,"srlv":0,"srav":0,
    "addi":0,"andi":0,"ori":0,"xori":0,"slti":0,"lui":0,"lw":0,
}
NO_DEST = {"sw","beq","bne","jr","j","nop"}

def dest_reg(mnem, toks):
    if mnem == "jal":
        return 31
    if mnem in DEST_REG_IDX:
        try:
            return reg(toks[DEST_REG_IDX[mnem]])
        except Exception:
            return None
    return None

def hazard_read_regs(mnem, toks):
    """registers read (for hazard purposes) by instructions resolved early (jr/beq/bne)"""
    try:
        if mnem == "jr":
            return [reg(toks[0])]
        if mnem in ("beq","bne"):
            return [reg(toks[0]), reg(toks[1])]
    except Exception:
        return []
    return []

def raw_pass(lines):
    """Strip comments/labels, return list of dicts: {label, mnem, args, toks}"""
    items = []
    for raw in lines:
        line = strip_comment(raw).strip()
        if not line:
            continue
        pending_label = None
        while True:
            m = re.match(r'^(\w+)\s*:\s*(.*)$', line)
            if m:
                pending_label = m.group(1)
                line = m.group(2).strip()
                if not line:
                    items.append({"label": pending_label, "mnem": None, "args": ""})
                    pending_label = None
                    break
                continue
            break
        if not line:
            continue
        parts = line.split(None, 1)
        mnem = parts[0].lower()
        args = parts[1] if len(parts) > 1 else ""
        toks = [t for t in tokenize(args) if t != ',']
        items.append({"label": pending_label, "mnem": mnem, "args": args, "toks": toks})
    return items

def insert_hazard_nops(items):
    """Insert 3 NOPs before jr/beq/bne if any of the preceding 3 real instructions
    write a register that instruction reads. Labels stay attached to the instruction
    they precede (a label pointing at a jr/beq/bne now points at the first inserted NOP,
    which is fine since NOPs are no-ops and control still lands at the intended spot only
    if nothing jumps INTO the middle of this hazard window; standard case is fully safe)."""
    out = []
    recent_writes = []  # list of sets of regs written by last few real instructions, most recent last
    for it in items:
        if it["mnem"] is None:
            # pure label line, no instruction; just pass through, doesn't affect hazard tracking
            out.append(it)
            continue
        mnem = it["mnem"]
        if mnem in ("jr","beq","bne"):
            reads = set(hazard_read_regs(mnem, it["toks"]))
            reads.discard(0)  # $0 never hazards
            conflict = any(reads & w for w in recent_writes[-3:])
            if conflict:
                # insert 3 NOPs, preserving this instruction's label on the FIRST nop
                nop_label = it["label"]
                for i in range(3):
                    out.append({"label": nop_label if i == 0 else None, "mnem": "nop", "args": "", "toks": []})
                it = dict(it)
                it["label"] = None
                # 3 NOPs reset the hazard window
                recent_writes = []
        out.append(it)
        d = dest_reg(mnem, it.get("toks", []))
        if mnem == "nop":
            recent_writes.append(set())
        elif d is not None and d != 0:
            recent_writes.append({d})
        else:
            recent_writes.append(set())
    return out

def first_pass(lines):
    """Full pipeline: comments/labels -> hazard NOP insertion -> address assignment."""
    items = raw_pass(lines)
    items = insert_hazard_nops(items)
    instrs = []
    labels = {}
    addr = 0
    for it in items:
        if it["label"]:
            labels[it["label"]] = addr
        if it["mnem"] is None:
            continue
        instrs.append([addr, it["mnem"], it["args"]])
        addr += 4
    return instrs, labels

def encode(addr, mnem, args, labels):
    toks = [t for t in tokenize(args) if t != ',']

    def R_encode(rs,rt,rd,shamt,funct):
        return (0<<26)|(rs<<21)|(rt<<16)|(rd<<11)|(shamt<<5)|funct

    def I_encode(op,rs,rt,imm):
        return (op<<26)|(rs<<21)|(rt<<16)|(imm & 0xFFFF)

    def J_encode(op,target):
        return (op<<26)|(target & 0x3FFFFFF)

    if mnem == "nop":
        return 0

    if mnem in RTYPE_RD_RS_RT or mnem in RTYPE_RD_RS_RT_MULDIV:
        rd = reg(toks[0]); rs = reg(toks[1]); rt = reg(toks[2])
        return R_encode(rs,rt,rd,0,R_FUNCT[mnem])

    if mnem in RTYPE_RD_RT_SHAMT:
        rd = reg(toks[0]); rt = reg(toks[1]); shamt = parse_imm(toks[2]) & 0x1F
        return R_encode(0,rt,rd,shamt,R_FUNCT[mnem])

    if mnem in RTYPE_RD_RT_RS:
        rd = reg(toks[0]); rt = reg(toks[1]); rs = reg(toks[2])
        return R_encode(rs,rt,rd,0,R_FUNCT[mnem])

    if mnem == "jr":
        rs = reg(toks[0])
        return R_encode(rs,0,0,0,R_FUNCT["jr"])

    if mnem in ("lw","sw"):
        rt = reg(toks[0])
        m = re.match(r'^(-?\w+)\s*\(\s*(\$\w+)\s*\)$', "".join(toks[1:]).replace(" ",""))
        if not m:
            raise ValueError(f"bad mem operand for {mnem}: {args}")
        imm = parse_imm(m.group(1))
        rs = reg(m.group(2))
        return I_encode(I_OP[mnem], rs, rt, imm)

    if mnem in ("addi","andi","ori","xori","slti"):
        rt = reg(toks[0]); rs = reg(toks[1]); imm = parse_imm(toks[2])
        return I_encode(I_OP[mnem], rs, rt, imm)

    if mnem == "lui":
        rt = reg(toks[0]); imm = parse_imm(toks[1])
        return I_encode(I_OP[mnem], 0, rt, imm)

    if mnem in ("beq","bne"):
        rs = reg(toks[0]); rt = reg(toks[1])
        target_tok = toks[2]
        if target_tok in labels:
            target_addr = labels[target_tok]
        else:
            target_addr = parse_imm(target_tok)
        offset = (target_addr - (addr+4)) // 4
        return I_encode(I_OP[mnem], rs, rt, offset)

    if mnem in ("j","jal"):
        target_tok = toks[0]
        if target_tok in labels:
            target_addr = labels[target_tok]
        else:
            target_addr = parse_imm(target_tok)
        return J_encode(J_OP[mnem], (target_addr >> 2) & 0x3FFFFFF)

    raise ValueError(f"unknown mnemonic: {mnem}")

def assemble(text):
    lines = text.splitlines()
    instrs, labels = first_pass(lines)
    words = []
    for addr, mnem, args in instrs:
        try:
            w = encode(addr, mnem, args, labels)
        except Exception as e:
            raise ValueError(f"line addr {addr} '{mnem} {args}': {e}")
        words.append((addr, w, mnem, args))
    return words

def to_mem_lines(words):
    out = []
    for addr, w, mnem, args in words:
        b = [(w>>24)&0xFF, (w>>16)&0xFF, (w>>8)&0xFF, w&0xFF]
        parts = " ".join(f"mem[{addr+i:5d}]=8'h{b[i]:02X};" for i in range(4))
        out.append(f"//{mnem} {args}".rstrip())
        out.append(parts)
    return out

def main():
    if len(sys.argv) < 2:
        print("usage: asm.py input.asm [output.v]"); sys.exit(1)
    with open(sys.argv[1]) as f:
        text = f.read()
    words = assemble(text)
    lines = to_mem_lines(words)
    out_text = "\n".join(lines)
    if len(sys.argv) > 2:
        with open(sys.argv[2], "w") as f:
            f.write(out_text + "\n")
    else:
        print(out_text)

if __name__ == "__main__":
    main()