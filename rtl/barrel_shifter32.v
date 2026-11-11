//==============================================================
// Authors : Mohammad Irtiqa Bhat (2024-25MECECS005), Mohammad Abbas (2025MECECS002)
// Institute: National Institute of Technology Srinagar, Dept. of Electronics and Communication Engineering
// File    : barrel_shifter32.v
// Desc    : 32-bit barrel shifter, 5 mux stages (shift by 1,2,4,8,16).
//           One right-shifter core is reused for left shifts by
//           reversing the bits at the input and at the output.
// mode    : 00 = SLL, 01 = SRL, 10 = SRA
//==============================================================
`timescale 1ns/1ps

module barrel_shifter32 (
    input  wire [31:0] data,
    input  wire [4:0]  shamt,
    input  wire [1:0]  mode,
    output wire [31:0] y
);
    function [31:0] rev;
        input [31:0] x;
        integer k;
        begin
            for (k = 0; k < 32; k = k + 1)
                rev[k] = x[31-k];
        end
    endfunction

    wire left = (mode == 2'b00);
    wire fill = (mode == 2'b10) & data[31];   // sign bit only for SRA

    wire [31:0] s0 = left ? rev(data) : data;
    wire [31:0] s1 = shamt[0] ? {     fill,  s0[31:1]}  : s0;
    wire [31:0] s2 = shamt[1] ? {{2{fill}},  s1[31:2]}  : s1;
    wire [31:0] s3 = shamt[2] ? {{4{fill}},  s2[31:4]}  : s2;
    wire [31:0] s4 = shamt[3] ? {{8{fill}},  s3[31:8]}  : s3;
    wire [31:0] s5 = shamt[4] ? {{16{fill}}, s4[31:16]} : s4;

    assign y = left ? rev(s5) : s5;
endmodule
