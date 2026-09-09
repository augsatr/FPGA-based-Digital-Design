module alu_32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] result,
    output wire        zero,
    output wire        negative
);

    localparam OP_ADD = 4'b0000;
    localparam OP_SUB = 4'b0001;
    localparam OP_AND = 4'b0010;
    localparam OP_OR  = 4'b0011;
    localparam OP_XOR = 4'b0100;
    localparam OP_NOT = 4'b0101;
    localparam OP_SLL = 4'b0110;
    localparam OP_SRL = 4'b0111;
    localparam OP_SRA = 4'b1000;
    localparam OP_SLT = 4'b1001;
    localparam OP_MUL = 4'b1010;
    localparam OP_DIV = 4'b1011;
    localparam OP_MOD = 4'b1100;
    localparam OP_NOP = 4'b1111;

    assign zero     = (result == 32'd0);
    assign negative = result[31];

    wire [63:0] mul_result = $signed(a) * $signed(b);
    wire [31:0] div_result = a / b;
    wire [31:0] mod_result = a % b;

    always @(*) begin
        case (alu_op)
            OP_ADD: result = a + b;
            OP_SUB: result = a - b;
            OP_AND: result = a & b;
            OP_OR:  result = a | b;
            OP_XOR: result = a ^ b;
            OP_NOT: result = ~a;
            OP_SLL: result = a << b[4:0];
            OP_SRL: result = a >> b[4:0];
            OP_SRA: result = $signed(a) >>> b[4:0];
            OP_SLT: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            OP_MUL: result = mul_result[31:0];
            OP_DIV: result = (b != 0) ? div_result : 32'hFFFFFFFF;
            OP_MOD: result = (b != 0) ? mod_result : 32'd0;
            OP_NOP: result = 32'd0;
            default: result = 32'd0;
        endcase
    end

endmodule
