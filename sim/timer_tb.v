`timescale 1ns / 1ps

module timer_tb;

    reg         clk;
    reg         rst;
    reg  [31:0] wdata;
    reg         we;
    reg         re;
    wire [31:0] rdata;
    wire        irq;

    localparam CLK_FREQ = 100_000_000;

    timer #(.CLK_FREQ(CLK_FREQ)) uut (
        .clk   (clk),
        .rst   (rst),
        .wdata (wdata),
        .we    (we),
        .re    (re),
        .rdata (rdata),
        .irq   (irq)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst = 1;
        wdata = 0;
        we = 0;
        re = 0;

        #100;
        rst = 0;
        #100;

        $display("=== Timer Test ===");

        // Set compare value to 100
        wdata = 32'h10000064; // command=1 (compare), value=100
        we = 1;
        @(posedge clk);
        we = 0;

        // Enable timer with interrupt
        wdata = 32'h20000003; // command=2, enable=1, irq_en=1
        we = 1;
        @(posedge clk);
        we = 0;

        // Wait for timer to reach compare value
        repeat(120) @(posedge clk);

        if (irq) begin
            $display("PASS: Timer IRQ fired");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Timer IRQ not fired");
            fail_count = fail_count + 1;
        end

        // Read timer count
        re = 1;
        @(posedge clk);
        re = 0;
        @(posedge clk);
        $display("  Timer count = %d", rdata);

        // Test auto-reload
        wdata = 32'h20000007; // enable=1, irq_en=1, auto_reload=1
        we = 1;
        @(posedge clk);
        we = 0;

        wdata = 32'h3000000A; // reload value = 10
        we = 1;
        @(posedge clk);
        we = 0;

        repeat(200) @(posedge clk);

        $display("  Timer count after auto-reload: %d", uut.timer_count);

        $display("");
        $display("=== Timer Test Summary ===");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("==========================");
        $finish;
    end

    initial begin
        $dumpfile("timer_tb.vcd");
        $dumpvars(0, timer_tb);
    end

endmodule
