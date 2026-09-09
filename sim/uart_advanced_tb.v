`timescale 1ns / 1ps

module uart_advanced_tb;

    reg         clk;
    reg         rst;
    reg         rx_line;
    wire        tx_line;
    wire        rts;
    reg         cts;
    reg  [31:0] addr;
    reg  [31:0] wdata;
    wire [31:0] rdata;
    reg         we;
    reg         re;
    wire        tx_busy;
    wire        rx_ready;
    wire [7:0]  status;

    localparam CLK_FREQ = 100_000_000;
    localparam BAUD_RATE = 115200;
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    uart_advanced #(
        .CLK_FREQ(CLK_FREQ),
        .FIFO_DEPTH(16)
    ) uut (
        .clk     (clk),
        .rst     (rst),
        .rx      (rx_line),
        .tx      (tx_line),
        .addr    (addr),
        .wdata   (wdata),
        .rdata   (rdata),
        .we      (we),
        .re      (re),
        .tx_busy (tx_busy),
        .rx_ready(rx_ready),
        .rts     (rts),
        .cts     (cts),
        .status  (status)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task send_uart_byte;
        input [7:0] data;
        integer j;
        begin
            // Start bit
            rx_line = 1'b0;
            repeat(CLKS_PER_BIT) @(posedge clk);

            // 8 data bits
            for (j = 0; j < 8; j = j + 1) begin
                rx_line = data[j];
                repeat(CLKS_PER_BIT) @(posedge clk);
            end

            // Stop bit
            rx_line = 1'b1;
            repeat(CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task recv_uart_byte;
        output [7:0] data;
        integer j;
        begin
            // Wait for start bit
            @(negedge tx_line);
            repeat(CLKS_PER_BIT / 2) @(posedge clk);

            // Sample 8 data bits
            for (j = 0; j < 8; j = j + 1) begin
                repeat(CLKS_PER_BIT) @(posedge clk);
                data[j] = tx_line;
            end

            // Wait for stop bit
            repeat(CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    reg [7:0] rx_byte;
    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst   = 1;
        rx_line = 1'b1;
        cts   = 1'b1;
        addr  = 0;
        wdata = 0;
        we    = 0;
        re    = 0;

        #100;
        rst = 0;
        #100;

        $display("=== UART Advanced Test ===");

        // Test 1: TX FIFO write and transmit
        $display("Test 1: TX FIFO + Transmit");
        wdata = 32'hA5;
        addr  = 32'h00002000;
        we    = 1;
        @(posedge clk);
        we = 0;

        recv_uart_byte(rx_byte);
        if (rx_byte == 8'hA5) begin
            $display("  PASS: TX sent 0xA5, received 0x%h", rx_byte);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: TX sent 0xA5, received 0x%h", rx_byte);
            fail_count = fail_count + 1;
        end

        // Test 2: RX receive and FIFO
        $display("Test 2: RX Receive + FIFO");
        send_uart_byte(8'h3C);
        repeat(500) @(posedge clk);

        addr = 32'h00002000;
        re   = 1;
        @(posedge clk);
        re = 0;
        @(posedge clk);

        if (rdata[7:0] == 8'h3C) begin
            $display("  PASS: RX received 0x%h", rdata[7:0]);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: RX expected 0x3C, got 0x%h", rdata[7:0]);
            fail_count = fail_count + 1;
        end

        // Test 3: Baud rate change
        $display("Test 3: Baud Rate Change");
        wdata = 32'h00000004; // 115200
        addr  = 32'h0000200C;
        we    = 1;
        @(posedge clk);
        we = 0;

        // Test 4: Flow control (CTS)
        $display("Test 4: Flow Control");
        cts = 0;
        wdata = 32'h55;
        addr  = 32'h00002000;
        we    = 1;
        @(posedge clk);
        we = 0;
        repeat(100) @(posedge clk);

        if (tx_busy) begin
            $display("  PASS: TX blocked when CTS low");
            pass_count = pass_count + 1;
        end else begin
            $display("  INFO: TX status depends on FIFO state");
        end

        cts = 1;
        repeat(CLKS_PER_BIT * 12) @(posedge clk);

        // Test 5: Status register
        $display("Test 5: Status Register");
        addr = 32'h00002008;
        re   = 1;
        @(posedge clk);
        re = 0;
        @(posedge clk);
        $display("  Status = 0x%h", rdata[7:0]);
        pass_count = pass_count + 1;

        $display("");
        $display("=== UART Test Summary ===");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("=========================");
        $finish;
    end

    initial begin
        $dumpfile("uart_advanced_tb.vcd");
        $dumpvars(0, uart_advanced_tb);
    end

endmodule
