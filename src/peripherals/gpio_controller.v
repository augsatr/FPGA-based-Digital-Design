module gpio_controller #(
    parameter PORTS = 16
)(
    input  wire        clk,
    input  wire        rst,
    // GPIO pins
    output wire [PORTS-1:0] gpio_out,
    input  wire [PORTS-1:0] gpio_in,
    output wire [PORTS-1:0] gpio_oe,
    // CPU interface
    input  wire [31:0] wdata,
    input  wire        we,
    input  wire        re,
    output reg  [31:0] rdata,
    // Interrupt
    output wire        irq
);

    reg [PORTS-1:0] out_reg;
    reg [PORTS-1:0] oe_reg;
    reg [PORTS-1:0] int_enable;
    reg [PORTS-1:0] int_edge_type;  // 0=level, 1=edge
    reg [PORTS-1:0] int_polarity;   // 0=low/falling, 1=high/rising
    reg [PORTS-1:0] prev_in;
    reg [PORTS-1:0] int_status;

    assign gpio_out = out_reg;
    assign gpio_oe  = oe_reg;

    wire [PORTS-1:0] edge_detected = (gpio_in ^ prev_in) & int_edge_type;
    wire [PORTS-1:0] level_match   = (gpio_in ~^ int_polarity) & ~int_edge_type;
    wire [PORTS-1:0] int_sources   = (edge_detected | level_match) & int_enable;

    assign irq = (int_sources != {PORTS{1'b0}});

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_reg     <= {PORTS{1'b0}};
            oe_reg      <= {PORTS{1'b0}};
            int_enable  <= {PORTS{1'b0}};
            int_edge_type <= {PORTS{1'b0}};
            int_polarity  <= {PORTS{1'b1}};
            prev_in     <= {PORTS{1'b0}};
            int_status  <= {PORTS{1'b0}};
        end else begin
            prev_in    <= gpio_in;
            int_status <= int_status | int_sources;

            if (we) begin
                case (wdata[31:28])
                    4'h0: out_reg       <= wdata[PORTS-1:0];
                    4'h1: oe_reg        <= wdata[PORTS-1:0];
                    4'h2: int_enable    <= wdata[PORTS-1:0];
                    4'h3: int_edge_type <= wdata[PORTS-1:0];
                    4'h4: int_polarity  <= wdata[PORTS-1:0];
                    4'hF: int_status    <= int_status & ~wdata[PORTS-1:0]; // W1C
                    default: ;
                endcase
            end
        end
    end

    always @(*) begin
        rdata = 32'd0;
        if (re) begin
            rdata[PORTS-1:0] = gpio_in;
        end
    end

endmodule
