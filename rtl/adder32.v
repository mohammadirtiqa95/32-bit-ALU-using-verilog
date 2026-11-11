//==============================================================
// Authors : Mohammad Irtiqa Bhat (2024-25MECECS005), Mohammad Abbas (2025MECECS002)
// Institute: National Institute of Technology Srinagar, Dept. of Electronics and Communication Engineering
// File    : adder32.v
// Desc    : 32-bit adder built from eight 4-bit carry-lookahead
//           (CLA) blocks. Carry ripples between blocks.
//==============================================================
`timescale 1ns/1ps

// ---------- 4-bit carry-lookahead block ----------
module cla4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] s,
    output wire       cout
);
    wire [3:0] p = a ^ b;   // propagate
    wire [3:0] g = a & b;   // generate

    wire c1 = g[0] | (p[0] & cin);
    wire c2 = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    wire c3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0])
                   | (p[2] & p[1] & p[0] & cin);
    assign cout = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1])
                       | (p[3] & p[2] & p[1] & g[0])
                       | (p[3] & p[2] & p[1] & p[0] & cin);

    assign s = p ^ {c3, c2, c1, cin};
endmodule

// ---------- 32-bit adder ----------
module adder32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire        cin,
    output wire [31:0] sum,
    output wire        cout
);
    wire [8:0] c;
    assign c[0] = cin;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : blk
            cla4 u (.a(a[4*i+3:4*i]), .b(b[4*i+3:4*i]), .cin(c[i]),
                    .s(sum[4*i+3:4*i]), .cout(c[i+1]));
        end
    endgenerate

    assign cout = c[8];
endmodule
