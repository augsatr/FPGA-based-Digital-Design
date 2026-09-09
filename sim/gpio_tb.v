`timescale 1ns / 1ps

module gpio_tb;

    reg         clk;
    reg         rst;
    wire [15:0] gpio_out;
    reg  [15:0] gpio_in;
    wire [15:0] gpio_oe;
    reg  [31:0] wdata;
    reg         we;
    reg         re;
    wire [31:0] rdata;
    wire        irq;

    gpio_controller #(.PORTS(16)) uut (
        .clk      (clk),
        .rst      (rst),
        .gpio_out (gpio_out),
        .gpio_in  (gpio_in),
        .gpio_oe  (gpio_oe),
        .wdata    (wdata),
        .we       (we),
        .re       (re),
        .rdata    (rdata),
        .irq      (irq)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst = 1;
        gpio_in = 0;
        wdata = 0;
        we = 0;
        re = 0;

        #100;
        rst = 0;
        #100;

        $display("=== GPIO Test ===");

        // Set output value
        wdata = 32'h0000AAAA; // cmd=0, data=0xAAAA
        we = 1;
        @(posedge clk);
        we = 0;

        if (gpio_out == 16'hAAAA) begin
            $display("PASS: GPIO output = 0x%h", gpio_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: GPIO output = 0x%h, expected 0xAAAA", gpio_out);
            fail_count = fail_count + 1;
        end

        // Set output enable
        wdata = 32'h1000FFFF; // cmd=1, all output
        we = 1;
        @(posedge clk);
        we = 0;

        if (gpio_oe == 16'hFFFF) begin
            $display("PASS: GPIO OE = 0x%h", gpio_oe);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: GPIO OE = 0x%h", gpio_oe);
            fail_count = fail_count + 1;
        end

        // Enable interrupt on pin 0 (edge, rising)
        wdata = 32'h20000001; // cmd=2, int_enable[0]=1
        we = 1;
        @(posedge clk);
        we = 0;

        wdata = 32'h30000001; // cmd=3, edge_type[0]=1
        we = 1;
        @(posedge clk);
        we = 0;

        wdata = 32'h40000001; // cmd=4, polarity[0]=1
        we = 1;
        @(posedge clk);
        we = 0;

        // Trigger interrupt
        gpio_in = 16'h0001;
        repeat(3) @(posedge clk);

        if (irq) begin
            $display("PASS: GPIO IRQ fired on rising edge");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: GPIO IRQ not fired");
            fail_count = fail_count + 1;
        end

        // Clear interrupt (W1C)
        wdata = 32'hF0000001; // cmd=F, clear[0]=1
        we = 1;
        @(posedge clk);
        we = 0;
        repeat(3) @(posedge clk);

        // Read GPIO input
        gpio_in = 16'hBEEF;
        re = 1;
        @(posedge clk);
        re = 0;
        @(posedge clk);

        if (rdata[15:0] == 16'hBEEF) begin
            $display("PASS: GPIO input read = 0x%h", rdata[15:0]);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: GPIO input read = 0x%h, expected 0xBEEF", rdata[15:0]);
            fail_count = fail_count + 1;
        end

        $display("");
        $display("=== GPIO Test Summary ===");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("=========================");
        $finish;
    end

    initial begin
        $dumpfile("gpio_tb.vcd");
        $dumpvars(0, gpio_tb);
    end

endmodule
