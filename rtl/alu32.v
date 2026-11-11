//==============================================================
// Authors : Mohammad Irtiqa Bhat (2024-25MECECS005), Mohammad Abbas (2025MECECS002)
// Institute: National Institute of Technology Srinagar, Dept. of Electronics and Communication Engineering
// File    : alu32.v   (TOP MODULE)
// Desc    : Combinational 32-bit ALU, 16 operations, 4 flags.
//   Flag convention (ARM style):
//     C = carry out of the adder (for SUB/DEC, C=1 means NO borrow)
//     V = signed overflow, N = result[31], Z = (result == 0)
//     C and V are only defined for ADD, SUB, INC, DEC (0 otherwise).
//==============================================================
`timescale 1ns/1ps

module alu32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  op,
    output reg  [31:0] result,
    output wire        zero,
    output wire        negative,
    output wire        carry,
    output wire        overflow
);
    // ---------------- opcode encoding ----------------
    localparam OP_ADD  = 4'b0000;
    localparam OP_SUB  = 4'b0001;
    localparam OP_AND  = 4'b0010;
    localparam OP_OR   = 4'b0011;
    localparam OP_XOR  = 4'b0100;
    localparam OP_NOR  = 4'b0101;
    localparam OP_NAND = 4'b0110;
    localparam OP_XNOR = 4'b0111;
    localparam OP_SLL  = 4'b1000;
    localparam OP_SRL  = 4'b1001;
    localparam OP_SRA  = 4'b1010;
    localparam OP_SLT  = 4'b1011;
    localparam OP_SLTU = 4'b1100;
    localparam OP_INC  = 4'b1101;
    localparam OP_DEC  = 4'b1110;
    localparam OP_NOT  = 4'b1111;

    // ------------- operand conditioning for the adder -------------
    //  ADD : a + b          SUB/SLT/SLTU : a + ~b + 1
    //  INC : a + 0 + 1      DEC          : a + 0xFFFFFFFF + 0
    reg [31:0] add_b;
    reg        add_cin;
    always @(*) begin
        case (op)
            OP_SUB, OP_SLT, OP_SLTU: begin add_b = ~b;           add_cin = 1'b1; end
            OP_INC:                  begin add_b = 32'd0;        add_cin = 1'b1; end
            OP_DEC:                  begin add_b = 32'hFFFFFFFF; add_cin = 1'b0; end
            default:                 begin add_b = b;            add_cin = 1'b0; end
        endcase
    end

    wire [31:0] add_sum;
    wire        add_cout;
    adder32 u_adder (.a(a), .b(add_b), .cin(add_cin), .sum(add_sum), .cout(add_cout));

    // signed overflow: operands have equal sign, result sign differs
    wire add_ovf = (a[31] == add_b[31]) & (add_sum[31] != a[31]);

    // ---------------- barrel shifter ----------------
    wire [1:0]  sh_mode = (op == OP_SLL) ? 2'b00 :
                          (op == OP_SRL) ? 2'b01 : 2'b10;
    wire [31:0] shift_y;
    barrel_shifter32 u_shift (.data(a), .shamt(b[4:0]), .mode(sh_mode), .y(shift_y));

    // ---------------- compare (re-uses the subtractor) ----------------
    wire slt_bit  = add_sum[31] ^ add_ovf;   // signed   a < b  (N xor V)
    wire sltu_bit = ~add_cout;               // unsigned a < b  (borrow)

    // ---------------- result multiplexer ----------------
    always @(*) begin
        case (op)
            OP_ADD, OP_SUB,
            OP_INC, OP_DEC : result = add_sum;
            OP_AND         : result = a & b;
            OP_OR          : result = a | b;
            OP_XOR         : result = a ^ b;
            OP_NOR         : result = ~(a | b);
            OP_NAND        : result = ~(a & b);
            OP_XNOR        : result = ~(a ^ b);
            OP_SLL, OP_SRL,
            OP_SRA         : result = shift_y;
            OP_SLT         : result = {31'd0, slt_bit};
            OP_SLTU        : result = {31'd0, sltu_bit};
            OP_NOT         : result = ~a;
            default        : result = 32'd0;
        endcase
    end

    // ---------------- status flags ----------------
    wire is_arith = (op == OP_ADD) | (op == OP_SUB) | (op == OP_INC) | (op == OP_DEC);

    assign zero     = (result == 32'd0);
    assign negative = result[31];
    assign carry    = is_arith & add_cout;
    assign overflow = is_arith & add_ovf;
endmodule
