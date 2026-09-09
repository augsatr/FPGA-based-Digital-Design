`timescale 1ns / 1ps

module interrupt_tb;

    reg         clk;
    reg         rst;
    reg  [7:0]  irq_sources;
    reg  [31:0] wdata;
    reg         we;
    reg         re;
    wire [31:0] rdata;
    wire        irq_out;
    reg         irq_ack;

    interrupt_controller uut (
        .clk        (clk),
        .rst        (rst),
        .irq_sources(irq_sources),
        .wdata      (wdata),
        .we         (we),
        .re         (re),
        .rdata      (rdata),
        .irq_out    (irq_out),
        .irq_ack    (irq_ack)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst = 1;
        irq_sources = 0;
        wdata = 0;
        we = 0;
        re = 0;
        irq_ack = 0;

        #100;
        rst = 0;
        #100;

        $display("=== Interrupt Controller Test ===");

        // Enable all interrupts
        wdata = 32'h0000FF00; // irq_enable[15:8] = 0xFF
        we = 1;
        @(posedge clk);
        we = 0;

        // Raise IRQ 0
        irq_sources = 8'h01;
        repeat(3) @(posedge clk);

        if (irq_out) begin
            $display("PASS: IRQ output asserted");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: IRQ output not asserted");
            fail_count = fail_count + 1;
        end

        // Read pending
        re = 1;
        @(posedge clk);
        re = 0;
        @(posedge clk);
        $display("  Pending=0x%h, Enable=0x%h", rdata[7:0], rdata[15:8]);

        if (rdata[0] == 1'b1) begin
            $display("PASS: IRQ 0 pending");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: IRQ 0 not pending");
            fail_count = fail_count + 1;
        end

        // Acknowledge
        irq_ack = 1;
        @(posedge clk);
        irq_ack = 0;
        irq_sources = 8'h00;
        repeat(3) @(posedge clk);

        if (!irq_out) begin
            $display("PASS: IRQ cleared after ack");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: IRQ still asserted after ack");
            fail_count = fail_count + 1;
        end

        // Multiple IRQs
        irq_sources = 8'hF0;
        repeat(3) @(posedge clk);
        re = 1;
        @(posedge clk);
        re = 0;
        @(posedge clk);
        $display("  Multiple pending: 0x%h", rdata[7:0]);

        // Priority test
        irq_ack = 1;
        @(posedge clk);
        irq_ack = 0;
        repeat(3) @(posedge clk);
        re = 1;
        @(posedge clk);
        re = 0;
        @(posedge clk);
        $display("  After ack one: 0x%h", rdata[7:0]);

        $display("");
        $display("=== Interrupt Test Summary ===");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("==============================");
        $finish;
    end

    initial begin
        $dumpfile("interrupt_tb.vcd");
        $dumpvars(0, interrupt_tb);
    end

endmodule
