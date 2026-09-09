module soc_top #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input  wire        clk,
    input  wire        rst_n,
    // UART
    input  wire        uart_rx,
    output wire        uart_tx,
    output wire        uart_rts,
    input  wire        uart_cts,
    // GPIO
    input  wire [15:0] gpio_in,
    output wire [15:0] gpio_out,
    output wire [15:0] gpio_oe,
    // Seven-segment
    output wire [6:0]  seg,
    output wire [3:0]  an,
    output wire        dp,
    // LEDs
    output wire [15:0] led,
    // Interrupt
    input  wire [7:0]  ext_irq
);

    wire rst = ~rst_n;

    // Bus signals
    wire [31:0] bus_addr, bus_wdata, bus_rdata;
    wire        bus_we, bus_re, bus_ready;

    // Instruction memory
    wire [31:0] imem_addr, imem_data;

    // Data memory
    wire [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    wire        dmem_we, dmem_re;
    wire [3:0]  dmem_be;

    // UART
    wire [31:0] uart_rdata;
    wire        uart_ready;
    wire        uart_tx_busy, uart_rx_ready;

    // Timer
    wire [31:0] timer_rdata;
    wire        timer_ready;
    wire        timer_irq;

    // GPIO
    wire [31:0] gpio_rdata;
    wire        gpio_ready;
    wire        gpio_irq;

    // Interrupt controller
    wire [31:0] int_rdata;
    wire        int_ready;
    wire        int_irq;
    wire        int_ack;

    // Combined interrupt
    wire [7:0]  irq_sources;
    assign irq_sources = {ext_irq[7:1], timer_irq};

    // Seven-segment display value
    reg [31:0] display_value;
    reg [3:0]  display_dots;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            display_value <= 32'd0;
            display_dots  <= 4'b0000;
        end else if (bus_we && bus_addr == 32'h00006000) begin
            display_value <= bus_wdata;
        end
    end

    // LED output
    reg [15:0] led_reg;
    always @(posedge clk or posedge rst) begin
        if (rst)
            led_reg <= 16'd0;
        else if (bus_we && bus_addr == 32'h00007000)
            led_reg <= bus_wdata[15:0];
    end
    assign led = led_reg;

    assign timer_ready = 1'b1;
    assign gpio_ready  = 1'b1;
    assign int_ready   = 1'b1;
    assign uart_ready  = 1'b1;

    // CPU
    cpu_pipeline u_cpu (
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
        .irq       (int_irq),
        .irq_ack   (int_ack)
    );

    // Instruction Memory
    instruction_memory #(.MEM_SIZE(256)) u_imem (
        .clk  (clk),
        .addr (imem_addr),
        .data (imem_data)
    );

    // Data Memory
    data_memory #(.MEM_SIZE(256)) u_dmem (
        .clk  (clk),
        .addr (dmem_addr),
        .wdata(dmem_wdata),
        .rdata(dmem_rdata),
        .we   (dmem_we),
        .re   (dmem_re),
        .be   (dmem_be)
    );

    // UART
    uart_advanced #(
        .CLK_FREQ(CLK_FREQ),
        .FIFO_DEPTH(16)
    ) u_uart (
        .clk     (clk),
        .rst     (rst),
        .rx      (uart_rx),
        .tx      (uart_tx),
        .addr    (bus_addr),
        .wdata   (bus_wdata),
        .rdata   (uart_rdata),
        .we      (bus_we && bus_addr[31:12] == 20'h00002),
        .re      (bus_re && bus_addr[31:12] == 20'h00002),
        .tx_busy (uart_tx_busy),
        .rx_ready(uart_rx_ready),
        .rts     (uart_rts),
        .cts     (uart_cts),
        .status  ()
    );

    // Timer
    timer #(.CLK_FREQ(CLK_FREQ)) u_timer (
        .clk    (clk),
        .rst    (rst),
        .wdata  (bus_wdata),
        .we     (bus_we && bus_addr[31:12] == 20'h00003),
        .re     (bus_re && bus_addr[31:12] == 20'h00003),
        .rdata  (timer_rdata),
        .irq    (timer_irq)
    );

    // GPIO
    gpio_controller #(.PORTS(16)) u_gpio (
        .clk      (clk),
        .rst      (rst),
        .gpio_out (gpio_out),
        .gpio_in  (gpio_in),
        .gpio_oe  (gpio_oe),
        .wdata    (bus_wdata),
        .we       (bus_we && bus_addr[31:12] == 20'h00004),
        .re       (bus_re && bus_addr[31:12] == 20'h00004),
        .rdata    (gpio_rdata),
        .irq      (gpio_irq)
    );

    // Interrupt Controller
    interrupt_controller u_intc (
        .clk        (clk),
        .rst        (rst),
        .irq_sources(irq_sources),
        .wdata      (bus_wdata),
        .we         (bus_we && bus_addr[31:12] == 20'h00005),
        .re         (bus_re && bus_addr[31:12] == 20'h00005),
        .rdata      (int_rdata),
        .irq_out    (int_irq),
        .irq_ack    (int_ack)
    );

    // Seven-segment display
    seven_seg_4digit u_seg (
        .clk   (clk),
        .value (display_value),
        .dots  (display_dots),
        .seg   (seg),
        .an    (an),
        .dp    (dp)
    );

endmodule
