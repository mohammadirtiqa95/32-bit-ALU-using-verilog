#!/usr/bin/env python3
"""Draws the block diagrams used in README.md  ->  docs/figures/*.png"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

BLUE, GREEN, ORANGE, GREY, PINK = "#cfe2ff", "#d1f0d6", "#ffe5b4", "#e8e8e8", "#f8d7da"

def box(ax, x, y, w, h, text, color=BLUE, fs=9, bold=False):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.08",
                                fc=color, ec="#333", lw=1.2))
    ax.text(x + w/2, y + h/2, text, ha="center", va="center", fontsize=fs,
            fontweight="bold" if bold else "normal")

def arrow(ax, x1, y1, x2, y2, label=None, lx=0, ly=0.12):
    ax.annotate("", xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle="-|>", lw=1.3, color="#222"))
    if label:
        ax.text((x1+x2)/2 + lx, (y1+y2)/2 + ly, label, ha="center", fontsize=8)

def line(ax, xs, ys):
    ax.plot(xs, ys, color="#222", lw=1.3)

def new(w, h, title):
    fig, ax = plt.subplots(figsize=(w, h))
    ax.set_xlim(0, w); ax.set_ylim(0, h); ax.axis("off")
    ax.set_title(title, fontsize=12, fontweight="bold")
    return fig, ax

# ---------------- Fig 1 : top level ----------------
def dot(ax, x, y):
    ax.plot([x], [y], "o", color="#222", ms=4)

fig, ax = new(12, 7.8, "32-bit ALU : top-level block diagram (alu32.v)")
box(ax, 0.2, 5.85, 1.6, 0.6, "A[31:0]", GREY, bold=True)
box(ax, 0.2, 5.10, 1.6, 0.6, "B[31:0]", GREY, bold=True)
box(ax, 0.2, 6.95, 1.6, 0.6, "OP[3:0]", GREY, bold=True)

box(ax, 3.1, 4.9, 1.7, 1.0, "Operand\nconditioning\n(B, ~B, 0, -1, cin)", ORANGE, fs=8)
box(ax, 5.6, 5.2, 2.4, 1.2, "32-bit adder\n8 x CLA4 blocks\nsum, Cout, V", GREEN, bold=True)
box(ax, 5.6, 3.9, 2.4, 1.0, "Compare logic\nSLT = N xor V\nSLTU = not Cout", GREEN, bold=True)
box(ax, 5.6, 2.5, 2.4, 1.0, "Logic unit\nAND OR XOR NOR\nNAND XNOR NOT", GREEN, bold=True)
box(ax, 5.6, 1.1, 2.4, 1.0, "Barrel shifter\nSLL  SRL  SRA\nshamt = B[4:0]", GREEN, bold=True)
box(ax, 8.9, 1.0, 1.1, 5.0, "Result\nMUX\n16 : 1\n\nselect\n= OP", PINK, bold=True)
box(ax, 10.4, 3.2, 1.5, 0.7, "RESULT[31:0]", GREY, bold=True, fs=8)
box(ax, 10.3, 6.2, 1.7, 0.8, "Flag unit\nZ  N  C  V", ORANGE, bold=True)

# operand buses
line(ax, [1.8, 2.1], [6.15, 6.15]); line(ax, [2.1, 2.1], [6.15, 1.9])        # A bus
line(ax, [1.8, 3.1], [5.4, 5.4]);  line(ax, [2.5, 2.5], [5.4, 1.3])          # B bus
arrow(ax, 2.1, 6.15, 5.6, 6.15) ; dot(ax, 2.1, 6.15)                          # A -> adder
arrow(ax, 2.1, 3.3, 5.6, 3.3);  dot(ax, 2.1, 3.3)                             # A -> logic
arrow(ax, 2.1, 1.9, 5.6, 1.9);  dot(ax, 2.1, 1.9)                             # A -> shifter
arrow(ax, 2.5, 2.7, 5.6, 2.7);  dot(ax, 2.5, 2.7)                             # B -> logic
arrow(ax, 2.5, 1.3, 5.6, 1.3);  dot(ax, 2.5, 1.3)                             # B[4:0] -> shifter
arrow(ax, 2.5, 5.4, 3.1, 5.4);  dot(ax, 2.5, 5.4)                             # B -> conditioning
arrow(ax, 4.8, 5.4, 5.6, 5.4)                                                 # cond -> adder
# adder -> compare
arrow(ax, 6.8, 5.2, 6.8, 4.9); ax.text(6.95, 5.02, "N, V, Cout", fontsize=7)
# unit outputs -> mux
arrow(ax, 8.0, 5.6, 8.9, 5.6); arrow(ax, 8.0, 4.4, 8.9, 4.4)
arrow(ax, 8.0, 3.0, 8.9, 3.0); arrow(ax, 8.0, 1.6, 8.9, 1.6)
arrow(ax, 10.0, 3.55, 10.4, 3.55)
# OP distribution
line(ax, [1.8, 9.45], [7.25, 7.25]); line(ax, [3.95, 3.95], [7.25, 5.9]); dot(ax, 3.95, 7.25)
arrow(ax, 3.95, 5.9, 3.95, 5.9)
ax.annotate("", xy=(3.95, 5.9), xytext=(3.95, 6.6), arrowprops=dict(arrowstyle="-|>", lw=1.3, color="#222"))
line(ax, [9.45, 9.45], [7.25, 6.0]); dot(ax, 9.45, 7.25)
ax.annotate("", xy=(9.45, 6.0), xytext=(9.45, 6.6), arrowprops=dict(arrowstyle="-|>", lw=1.3, color="#222"))
# flags
line(ax, [8.0, 8.3], [6.3, 6.3]); line(ax, [8.3, 8.3], [6.3, 6.55]); line(ax, [8.3, 10.3], [6.55, 6.55])
ax.text(8.45, 6.62, "C, V", fontsize=7)
ax.annotate("", xy=(11.15, 6.2), xytext=(11.15, 3.9), arrowprops=dict(arrowstyle="-|>", lw=1.3, color="#222"))
ax.text(11.3, 5.0, "Z, N", fontsize=7)
ax.text(0.2, 0.35, "C and V are valid only for ADD, SUB, INC, DEC. SLT/SLTU reuse the adder as a subtractor.",
        fontsize=8, style="italic")
fig.savefig("docs/figures/alu_block_diagram.png", dpi=170, bbox_inches="tight"); plt.close(fig)

# ---------------- Fig 2 : adder ----------------
fig, ax = new(12, 4.8, "32-bit adder (adder32.v): eight 4-bit carry-lookahead blocks")
for i in range(8):
    x = 0.4 + i * 1.4
    box(ax, x, 1.8, 1.1, 1.3, f"cla4\nbits\n[{4*i+3}:{4*i}]", GREEN)
    arrow(ax, x + 0.55, 3.9, x + 0.55, 3.1)
    ax.text(x + 0.55, 4.05, f"a,b[{4*i+3}:{4*i}]", ha="center", fontsize=7)
    arrow(ax, x + 0.55, 1.8, x + 0.55, 1.1)
    ax.text(x + 0.55, 0.85, f"s[{4*i+3}:{4*i}]", ha="center", fontsize=7)
    if i < 7:
        arrow(ax, x + 1.1, 2.45, x + 1.4, 2.45)
        ax.text(x + 1.25, 2.6, f"c{i+1}", ha="center", fontsize=8)
ax.text(0.15, 2.45, "cin", ha="center", fontsize=9)
arrow(ax, 0.0, 2.3, 0.4, 2.3)
ax.text(11.8, 2.6, "cout", ha="center", fontsize=9)
ax.text(6, 0.3, "Inside each block:  p = a xor b,  g = a and b,  c(k+1) = g(k) + p(k).c(k)  (expanded, 4-bit lookahead)",
        ha="center", fontsize=8.5, style="italic")
fig.savefig("docs/figures/adder_cla.png", dpi=170, bbox_inches="tight"); plt.close(fig)

# ---------------- Fig 3 : shifter ----------------
fig, ax = new(12, 4.2, "Barrel shifter (barrel_shifter32.v): 5 mux stages, one right-shift core")
box(ax, 0.2, 1.4, 1.3, 1.2, "DATA\n[31:0]", GREY, bold=True)
box(ax, 1.9, 1.4, 1.3, 1.2, "bit reverse\n(only for SLL)", ORANGE)
stages = [1, 2, 4, 8, 16]
for k, n in enumerate(stages):
    x = 3.6 + k * 1.45
    box(ax, x, 1.4, 1.1, 1.2, f"stage {k}\n>> {n}\n(shamt[{k}])", GREEN)
    arrow(ax, x + 0.55, 0.5, x + 0.55, 1.4)
arrow(ax, 1.5, 2.0, 1.9, 2.0)
arrow(ax, 3.2, 2.0, 3.6, 2.0)
for k in range(4):
    arrow(ax, 3.6 + k * 1.45 + 1.1, 2.0, 3.6 + (k + 1) * 1.45, 2.0)
box(ax, 10.9, 1.4, 1.0, 1.2, "bit\nreverse\n(SLL)", ORANGE)
arrow(ax, 3.6 + 4 * 1.45 + 1.1, 2.0, 10.9, 2.0)
ax.text(6.5, 3.4, "fill bit = sign bit for SRA, 0 for SLL/SRL.   mode: 00 SLL, 01 SRL, 10 SRA", ha="center", fontsize=9)
ax.text(6.5, 0.15, "shift amount = B[4:0]   (stages enabled by each bit)", ha="center", fontsize=9, style="italic")
fig.savefig("docs/figures/barrel_shifter.png", dpi=170, bbox_inches="tight"); plt.close(fig)
print("figures written")
