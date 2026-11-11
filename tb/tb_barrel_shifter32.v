//==============================================================
// Authors : Mohammad Irtiqa Bhat (2024-25MECECS005), Mohammad Abbas (2025MECECS002)
// Institute: National Institute of Technology Srinagar, Dept. of Electronics and Communication Engineering
// File : tb_barrel_shifter32.v -- unit test of barrel_shifter32
//==============================================================
`timescale 1ns/1ps

module tb_barrel_shifter32;
    reg  [31:0] d;
    reg  [4:0]  sh;
    reg  [1:0]  mode;
    wire [31:0] y;
    reg  signed [31:0] sd;
    reg  [31:0] e;
    integer errors = 0, checks = 0, i, k, seed = 99;

    barrel_shifter32 dut (.data(d), .shamt(sh), .mode(mode), .y(y));

    task chk;
        input [31:0] x;
        input [4:0]  s;
        input [1:0]  m;
        begin
            d = x; sh = s; mode = m; sd = x; #2;
            case (m)
                2'b00: e = x << s;
                2'b01: e = x >> s;
                default: e = sd >>> s;
            endcase
            checks = checks + 1;
            if (y !== e) begin
                errors = errors + 1;
                $display("FAIL mode=%b d=%h sh=%0d -> %h (exp %h)", m, x, s, y, e);
            end
        end
    endtask

    initial begin
        for (k = 0; k < 3; k = k + 1)
            for (i = 0; i < 32; i = i + 1) begin
                chk(32'h00000001, i[4:0], k[1:0]);
                chk(32'h80000000, i[4:0], k[1:0]);
                chk(32'hFFFFFFFF, i[4:0], k[1:0]);
                chk(32'h12345678, i[4:0], k[1:0]);
            end
        for (i = 0; i < 20000; i = i + 1)
            chk($random(seed), $random(seed), ($random(seed) & 32'h7FFFFFFF) % 3);
        $display("barrel shifter : checks=%0d errors=%0d", checks, errors);
        if (errors == 0) $display(">>> ALL TESTS PASSED <<<");
        else             $display(">>> TESTS FAILED <<<");
        $finish;
    end
endmodule
