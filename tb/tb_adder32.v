//==============================================================
// Authors : Mohammad Irtiqa Bhat (2024-25MECECS005), Mohammad Abbas (2025MECECS002)
// Institute: National Institute of Technology Srinagar, Dept. of Electronics and Communication Engineering
// File : tb_adder32.v -- unit test of cla4 and adder32
//==============================================================
`timescale 1ns/1ps

module tb_adder32;
    reg  [31:0] a, b;
    reg         cin;
    wire [31:0] sum;
    wire        cout;
    reg  [3:0]  qa, qb;
    reg         qc;
    wire [3:0]  qs;
    wire        qco;
    integer errors = 0, checks = 0, i, seed = 7;

    adder32 dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));
    cla4    blk (.a(qa), .b(qb), .cin(qc), .s(qs), .cout(qco));

    task chk;
        input [31:0] x, y;
        input        c;
        reg   [32:0] e;
        begin
            a = x; b = y; cin = c; #2;
            e = {1'b0, x} + {1'b0, y} + c;
            checks = checks + 1;
            if ({cout, sum} !== e) begin
                errors = errors + 1;
                $display("FAIL adder a=%h b=%h cin=%b -> %h%h (exp %h)", x, y, c, cout, sum, e);
            end
        end
    endtask

    initial begin
        // exhaustive test of the 4-bit CLA block (512 combinations)
        for (i = 0; i < 512; i = i + 1) begin
            {qc, qa, qb} = i[8:0]; #1;
            checks = checks + 1;
            if ({qco, qs} !== ({1'b0, qa} + {1'b0, qb} + qc)) begin
                errors = errors + 1;
                $display("FAIL cla4 a=%h b=%h cin=%b", qa, qb, qc);
            end
        end
        // carry must ripple through all 8 blocks
        chk(32'hFFFFFFFF, 32'h00000000, 1'b1);
        chk(32'hFFFFFFFF, 32'hFFFFFFFF, 1'b1);
        chk(32'h00000000, 32'h00000000, 1'b0);
        chk(32'h7FFFFFFF, 32'h00000001, 1'b0);
        for (i = 0; i < 20000; i = i + 1)
            chk($random(seed), $random(seed), $random(seed) & 1);
        $display("adder32/cla4 : checks=%0d errors=%0d", checks, errors);
        if (errors == 0) $display(">>> ALL TESTS PASSED <<<");
        else             $display(">>> TESTS FAILED <<<");
        $finish;
    end
endmodule
