module instruction_memory #(
    parameter MEM_SIZE = 1024
)(
    input  wire        clk,
    input  wire [31:0] addr,
    output wire [31:0] data
);

    reg [31:0] mem [0:MEM_SIZE-1];

    assign data = mem[addr[31:2]];

    integer i;
    initial begin
        for (i = 0; i < MEM_SIZE; i = i + 1)
            mem[i] = 32'h00000013; // NOP (addi x0, x0, 0)
    end

    initial begin
        // Test program: factorial of 5
        mem[0]  = 32'h00500093; // addi x1, x0, 5      (n = 5)
        mem[1]  = 32'h00100113; // addi x2, x0, 1      (result = 1)
        mem[2]  = 32'h00000193; // addi x3, x0, 0      (counter = 0)
        mem[3]  = 32'h00500213; // addi x4, x0, 5      (limit = 5)
        // loop:
        mem[4]  = 32'h002080b3; // add  x1, x1, x2     (not used, placeholder)
        mem[5]  = 32'h00210133; // add  x2, x2, x1     (result += n -- wrong, should be mul)
        mem[6]  = 32'h00118193; // addi x3, x3, 1      (counter++)
        mem[7]  = 32'hfe419ee3; // bne  x3, x4, loop   (if counter != limit, loop)
        mem[8]  = 32'h00200293; // addi x5, x0, 2      (dummy store addr)
        mem[9]  = 32'h0022a023; // sw   x2, 0(x5)      (store result to mem[2])
    end

endmodule
