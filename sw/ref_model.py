#!/usr/bin/env python3
"""Reference model + vector generator for the 32-bit ALU.

1. model()      : plain-integer reference (the "golden" behaviour).
2. struct_alu() : bit-level emulation of the RTL structure
                  (CLA4 chain, 5-stage barrel shifter, SLT = N xor V ...).
3. Cross-checks 1 against 2 on corner + random vectors, then writes
   tb/vectors.mem for the Verilog testbench ($readmemh).
Line format (26 hex digits): op(1) a(8) b(8) expected(8) flags(1) ; flags = {N,Z,C,V}
"""
import random

M = 0xFFFFFFFF
OPS = ["ADD","SUB","AND","OR","XOR","NOR","NAND","XNOR",
       "SLL","SRL","SRA","SLT","SLTU","INC","DEC","NOT"]

def s32(x):
    return x - (1 << 32) if x & 0x80000000 else x

def model(op, a, b):
    c = v = 0
    if   op == 0: r = (a + b) & M; c = (a + b) >> 32; v = not (-2**31 <= s32(a)+s32(b) < 2**31)
    elif op == 1: r = (a - b) & M; c = int(a >= b);   v = not (-2**31 <= s32(a)-s32(b) < 2**31)
    elif op == 2: r = a & b
    elif op == 3: r = a | b
    elif op == 4: r = a ^ b
    elif op == 5: r = ~(a | b) & M
    elif op == 6: r = ~(a & b) & M
    elif op == 7: r = ~(a ^ b) & M
    elif op == 8: r = (a << (b & 31)) & M
    elif op == 9: r = a >> (b & 31)
    elif op == 10: r = (s32(a) >> (b & 31)) & M
    elif op == 11: r = int(s32(a) < s32(b))
    elif op == 12: r = int(a < b)
    elif op == 13: r = (a + 1) & M; c = int(a == M);  v = int(a == 0x7FFFFFFF)
    elif op == 14: r = (a - 1) & M; c = int(a != 0);  v = int(a == 0x80000000)
    else:          r = ~a & M
    n = r >> 31; z = int(r == 0)
    return r, (n << 3) | (z << 2) | (int(c) << 1) | int(v)

# ---------- structural emulation of the RTL ----------
def cla4(a, b, cin):
    p, g = a ^ b, a & b
    bit = lambda x, i: (x >> i) & 1
    c1 = bit(g,0) | (bit(p,0) & cin)
    c2 = bit(g,1) | (bit(p,1)&bit(g,0)) | (bit(p,1)&bit(p,0)&cin)
    c3 = bit(g,2) | (bit(p,2)&bit(g,1)) | (bit(p,2)&bit(p,1)&bit(g,0)) | (bit(p,2)&bit(p,1)&bit(p,0)&cin)
    co = bit(g,3) | (bit(p,3)&bit(g,2)) | (bit(p,3)&bit(p,2)&bit(g,1)) | \
         (bit(p,3)&bit(p,2)&bit(p,1)&bit(g,0)) | (bit(p,3)&bit(p,2)&bit(p,1)&bit(p,0)&cin)
    s = (p ^ ((c3 << 3) | (c2 << 2) | (c1 << 1) | cin)) & 0xF
    return s, co

def adder32(a, b, cin):
    s, c = 0, cin
    for i in range(8):
        si, c = cla4((a >> 4*i) & 0xF, (b >> 4*i) & 0xF, c)
        s |= si << 4*i
    return s, c

def rev(x):
    return int(format(x, "032b")[::-1], 2)

def barrel(data, sh, mode):  # mode 0 SLL, 1 SRL, 2 SRA
    left = mode == 0
    fill = (data >> 31) & 1 if mode == 2 else 0
    x = rev(data) if left else data
    for k in range(5):
        if (sh >> k) & 1:
            n = 1 << k
            x = (x >> n) | ((M << (32 - n)) & M if fill else 0)
    return rev(x) if left else x

def struct_alu(op, a, b):
    add_b, cin = b, 0
    if op in (1, 11, 12): add_b, cin = ~b & M, 1
    elif op == 13:        add_b, cin = 0, 1
    elif op == 14:        add_b, cin = M, 0
    s, co = adder32(a, add_b, cin)
    ovf = int(((a >> 31) == (add_b >> 31)) and ((s >> 31) != (a >> 31)))
    if   op in (0, 1, 13, 14): r = s
    elif op == 2:  r = a & b
    elif op == 3:  r = a | b
    elif op == 4:  r = a ^ b
    elif op == 5:  r = ~(a | b) & M
    elif op == 6:  r = ~(a & b) & M
    elif op == 7:  r = ~(a ^ b) & M
    elif op in (8, 9, 10): r = barrel(a, b & 31, {8:0, 9:1, 10:2}[op])
    elif op == 11: r = ((s >> 31) ^ ovf) & 1
    elif op == 12: r = (~co) & 1
    else:          r = ~a & M
    arith = op in (0, 1, 13, 14)
    n = r >> 31; z = int(r == 0)
    return r, (n << 3) | (z << 2) | ((co if arith else 0) << 1) | (ovf if arith else 0)

if __name__ == "__main__":
    random.seed(2025)
    corner = [0, 1, M, 0x7FFFFFFF, 0x80000000, 0xAAAAAAAA, 0x55555555, 0x0000FFFF, 31, 32]
    vecs = [(op, a, b) for op in range(16) for a in corner for b in corner]
    for _ in range(1500):
        pick = lambda: random.choice(corner) if random.random() < 0.25 else random.getrandbits(32)
        vecs.append((random.randrange(16), pick(), pick()))
    bad = 0
    with open("tb/vectors.mem", "w") as f:
        for op, a, b in vecs:
            r, fl = model(op, a, b)
            if struct_alu(op, a, b) != (r, fl):
                bad += 1
            f.write(f"{op:01x}{a:08x}{b:08x}{r:08x}{fl:01x}\n")
    print(f"vectors written : {len(vecs)}  (tb/vectors.mem)")
    print(f"model vs RTL-structure emulation mismatches : {bad}")
    extra = 0
    for _ in range(200000):
        op, a, b = random.randrange(16), random.getrandbits(32), random.getrandbits(32)
        extra += struct_alu(op, a, b) != model(op, a, b)
    print(f"extra random cross-check (200000 vectors) mismatches : {extra}")
