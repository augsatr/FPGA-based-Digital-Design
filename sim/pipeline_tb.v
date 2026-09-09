`timescale 1ns / 1ps

module pipeline_tb;

    reg         clk;
    reg         rst;
    wire [31:0] imem_addr;
    reg  [31:0] imem_data;
    wire [31:0] dmem_addr, dmem_wdata;
    reg  [31:0] dmem_rdata;
    wire        dmem_we, dmem_re;
    wire [3:0]  dmem_be;
    wire        irq;
    wire        irq_ack;

    reg [31:0] imem [0:255];
    reg [31:0] dmem [0:255];

    cpu_pipeline uut (
        .clk       (clk),
        .rst       (rst),
        .imem_addr (imem_addr),
        .imem_data (imem_data),
        .dmem_addr (dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata),
        .dmem_we   (dmem_we),
        .dmem_re   (dmem_re),
        .dmem_be   (dmem_be),
        .irq       (irq),
        .irq_ack   (irq_ack)
    );

    assign imem_data = imem[imem_addr[31:2] & 8'hFF];

    always @(posedge clk) begin
        if (dmem_we) begin
            if (dmem_be[0]) dmem[dmem_addr[9:2]][7:0]   <= dmem_wdata[7:0];
            if (dmem_be[1]) dmem[dmem_addr[9:2]][15:8]  <= dmem_wdata[15:8];
            if (dmem_be[2]) dmem[dmem_addr[9:2]][23:16] <= dmem_wdata[23:16];
            if (dmem_be[3]) dmem[dmem_addr[9:2]][31:24] <= dmem_wdata[31:24];
        end
        dmem_rdata <= dmem[dmem_addr[9:2] & 8'hFF];
    end

    initial clk = 0;
    always #5 clk = ~clk;

    assign irq = 1'b0;

    integer i;

    initial begin
        rst = 1;

        for (i = 0; i < 256; i = i + 1) begin
            imem[i] = 32'h00000013; // NOP
            dmem[i] = 32'd0;
        end

        // Test program: data forwarding
        imem[0]  = 32'h00500093; // addi x1, x0, 5
        imem[1]  = 32'h00300113; // addi x2, x0, 3
        imem[2]  = 32'h002081b3; // add  x3, x1, x2    (hazard: x1, x2 from prev)
        imem[3]  = 32'h40218233; // sub  x4, x3, x2    (forward x3 from EX)
        imem[4]  = 32'h004102b3; // add  x5, x2, x4    (forward x4 from EX)
        imem[5]  = 32'h00500313; // addi x6, x0, 5
        imem[6]  = 32'h006283b3; // add  x7, x5, x6
        imem[7]  = 32'h00000013; // NOP
        imem[8]  = 32'h00000013; // NOP
        imem[9]  = 32'h00700413; // addi x8, x0, 7

        // Load-use hazard test
        imem[10] = 32'h00002483; // lw   x9, 0(x0)
        imem[11] = 32'h00900533; // add  x10, x0, x9   (stall + forward)

        // Branch test
        imem[12] = 32'h00a00593; // addi x11, x0, 10
        imem[13] = 32'h00a00613; // addi x12, x0, 10
        imem[14] = 32'h00c58063; // beq  x11, x12, +8  (should be taken)
        imem[15] = 32'h00100093; // addi x1, x0, 1     (should be flushed)
        imem[16] = 32'h0ff00093; // addi x1, x0, 0xFF  (target)

        #100;
        rst = 0;

        // Run for enough cycles
        repeat(40) @(posedge clk);

        $display("=== Pipeline Forwarding Test ===");
        $display("x1  = %d (expect 255)", uut.u_rf.registers[1]);
        $display("x3  = %d (expect 8)",   uut.u_rf.registers[3]);
        $display("x4  = %d (expect 5)",   uut.u_rf.registers[4]);
        $display("x5  = %d (expect 8)",   uut.u_rf.registers[5]);
        $display("x7  = %d (expect 13)",  uut.u_rf.registers[7]);
        $display("x11 = %d (expect 10)",  uut.u_rf.registers[11]);
        $display("x12 = %d (expect 10)",  uut.u_rf.registers[12]);
        $display("=== Branch Test ===");
        $display("Branch should have flushed instruction at PC=0x3C");

        $finish;
    end

    initial begin
        $dumpfile("pipeline_tb.vcd");
        $dumpvars(0, pipeline_tb);
    end

endmodule
