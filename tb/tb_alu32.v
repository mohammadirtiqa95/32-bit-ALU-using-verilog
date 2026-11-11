//==============================================================
// Authors : Mohammad Irtiqa Bhat (2024-25MECECS005), Mohammad Abbas (2025MECECS002)
// Institute: National Institute of Technology Srinagar, Dept. of Electronics and Communication Engineering
// File : tb_alu32.v  -- self-checking system testbench for alu32
//   * independent behavioural reference model (task "model")
//   * directed corner tests, all shift amounts, random regression
//   * golden-vector file tb/vectors.mem (made by sw/ref_model.py)
//   * per-operation coverage counters
// Run from the project root:  sh run_sim.sh
//==============================================================
`timescale 1ns/1ps

module tb_alu32;
    parameter NV = 3100;

    reg  [31:0] a, b;
    reg  [3:0]  op;
    wire [31:0] result;
    wire        zero, negative, carry, overflow;

    integer errors = 0, checks = 0, i, j, seed = 32'h1234ABCD;
    integer cov [0:15];
    reg [31:0] corner [0:7];
    reg [103:0] vec_mem [0:NV-1];
    reg [31:0] e_res;
    reg        e_c, e_v;

    alu32 dut (.a(a), .b(b), .op(op), .result(result), .zero(zero),
               .negative(negative), .carry(carry), .overflow(overflow));

    // ---------- reference model (different method from the RTL) ----------
    task model;
        input  [3:0]  o;
        input  [31:0] x, y;
        output [31:0] r;
        output        c, v;
        reg [32:0] s33;
        reg [33:0] s34;
        reg signed [31:0] sx, sy;
        begin
            c = 0; v = 0; r = 0; sx = x; sy = y;
            case (o)
                4'b0000: begin
                    s33 = {1'b0, x} + {1'b0, y};  r = s33[31:0];  c = s33[32];
                    s34 = {x[31], x[31], x} + {y[31], y[31], y};  v = s34[33] ^ s34[32];
                end
                4'b0001: begin
                    r = x - y;  c = (x >= y);
                    s34 = {x[31], x[31], x} - {y[31], y[31], y};  v = s34[33] ^ s34[32];
                end
                4'b0010: r = x & y;
                4'b0011: r = x | y;
                4'b0100: r = x ^ y;
                4'b0101: r = ~(x | y);
                4'b0110: r = ~(x & y);
                4'b0111: r = ~(x ^ y);
                4'b1000: r = x << y[4:0];
                4'b1001: r = x >> y[4:0];
                4'b1010: r = sx >>> y[4:0];
                4'b1011: r = (sx < sy) ? 32'd1 : 32'd0;
                4'b1100: r = (x < y)   ? 32'd1 : 32'd0;
                4'b1101: begin r = x + 32'd1; c = (x == 32'hFFFFFFFF); v = (x == 32'h7FFFFFFF); end
                4'b1110: begin r = x - 32'd1; c = (x != 32'd0);        v = (x == 32'h80000000); end
                4'b1111: r = ~x;
            endcase
        end
    endtask

    // ---------- apply one vector and compare ----------
    task check;
        input [3:0]  o;
        input [31:0] x, y;
        begin
            op = o; a = x; b = y;
            #5;
            model(o, x, y, e_res, e_c, e_v);
            checks = checks + 1;
            cov[o] = cov[o] + 1;
            if (result !== e_res || carry !== e_c || overflow !== e_v ||
                zero !== (e_res == 32'd0) || negative !== e_res[31]) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("FAIL op=%b a=%h b=%h : res=%h (exp %h) C=%b/%b V=%b/%b",
                              o, x, y, result, e_res, carry, e_c, overflow, e_v);
            end
        end
    endtask

    function [31:0] pick;
        input dummy;
        begin
            if (($random(seed) & 3) == 0) pick = corner[$random(seed) & 7];
            else                          pick = $random(seed);
        end
    endfunction

    initial begin
        $dumpfile("sim/alu32.vcd");
        $dumpvars(0, tb_alu32);

        for (i = 0; i < 16; i = i + 1) cov[i] = 0;
        corner[0] = 32'h00000000; corner[1] = 32'h00000001;
        corner[2] = 32'hFFFFFFFF; corner[3] = 32'h7FFFFFFF;
        corner[4] = 32'h80000000; corner[5] = 32'hAAAAAAAA;
        corner[6] = 32'h55555555; corner[7] = 32'h0000FFFF;

        // T1 : known-answer tests
        check(4'b0000, 32'd10, 32'd20);
        check(4'b0001, 32'd50, 32'd20);
        check(4'b0000, 32'hFFFFFFFF, 32'd1);          // carry out
        check(4'b0000, 32'h7FFFFFFF, 32'd1);          // signed overflow
        check(4'b0001, 32'h80000000, 32'd1);          // signed overflow
        check(4'b0001, 32'd5, 32'd10);                // borrow
        check(4'b1011, 32'hFFFFFFFF, 32'd1);          // -1 < 1 (signed)
        check(4'b1100, 32'hFFFFFFFF, 32'd1);          // not < (unsigned)
        check(4'b1010, 32'h80000000, 32'd4);          // SRA keeps sign
        $display("T1 known-answer          done  (errors so far: %0d)", errors);

        // T2 : every operation on every corner pair
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 64; j = j + 1)
                check(i[3:0], corner[j / 8], corner[j % 8]);
        $display("T2 corner x corner       done  (errors so far: %0d)", errors);

        // T3 : all 32 shift amounts for SLL/SRL/SRA
        for (i = 8; i < 11; i = i + 1)
            for (j = 0; j < 32; j = j + 1) begin
                check(i[3:0], 32'h80000001, j);
                check(i[3:0], 32'h12345678, j);
                check(i[3:0], 32'hF0F0F0F0, {27'd0, j[4:0]} | 32'hFFFFFFE0); // upper bits ignored
            end
        $display("T3 all shift amounts     done  (errors so far: %0d)", errors);

        // T4 : constrained random regression
        for (i = 0; i < 20000; i = i + 1)
            check($random(seed), pick(0), pick(0));
        $display("T4 random (20000)        done  (errors so far: %0d)", errors);

        // T5 : golden vectors from the Python model
        for (i = 0; i < NV; i = i + 1) vec_mem[i] = {104{1'bx}};
        $readmemh("tb/vectors.mem", vec_mem);
        for (i = 0; i < NV; i = i + 1)
            if ((^vec_mem[i]) !== 1'bx) begin
                op = vec_mem[i][103:100]; a = vec_mem[i][99:68]; b = vec_mem[i][67:36];
                #5;
                checks = checks + 1;
                if (result !== vec_mem[i][35:4] ||
                    {negative, zero, carry, overflow} !== vec_mem[i][3:0]) begin
                    errors = errors + 1;
                    if (errors <= 20)
                        $display("FAIL(vec %0d) op=%b a=%h b=%h : res=%h exp=%h flags=%b exp=%b",
                                  i, op, a, b, result, vec_mem[i][35:4],
                                  {negative, zero, carry, overflow}, vec_mem[i][3:0]);
                end
            end
        $display("T5 golden vectors        done  (errors so far: %0d)", errors);

        $display("--------------------------------------------------");
        $display("FUNCTIONAL COVERAGE (checks per opcode)");
        $display("ADD=%0d SUB=%0d AND=%0d OR=%0d XOR=%0d NOR=%0d NAND=%0d XNOR=%0d",
                 cov[0], cov[1], cov[2], cov[3], cov[4], cov[5], cov[6], cov[7]);
        $display("SLL=%0d SRL=%0d SRA=%0d SLT=%0d SLTU=%0d INC=%0d DEC=%0d NOT=%0d",
                 cov[8], cov[9], cov[10], cov[11], cov[12], cov[13], cov[14], cov[15]);
        $display("checks performed : %0d", checks);
        $display("errors           : %0d", errors);
        if (errors == 0) $display(">>> ALL TESTS PASSED <<<");
        else             $display(">>> TESTS FAILED <<<");
        $display("--------------------------------------------------");
        $finish;
    end
endmodule
