module timer #(
    parameter CLK_FREQ = 100_000_000
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] wdata,
    input  wire        we,
    input  wire        re,
    output reg  [31:0] rdata,
    output reg         irq
);

    reg [31:0] timer_count;
    reg [31:0] timer_compare;
    reg        timer_enable;
    reg        timer_irq_enable;
    reg        timer_auto_reload;
    reg [31:0] timer_reload_val;

    wire timer_expired = (timer_count >= timer_compare) && timer_enable;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            timer_count      <= 32'd0;
            timer_compare    <= 32'hFFFFFFFF;
            timer_enable     <= 1'b0;
            timer_irq_enable <= 1'b0;
            timer_auto_reload <= 1'b0;
            timer_reload_val <= 32'd0;
            irq              <= 1'b0;
        end else begin
            irq <= 1'b0;

            if (timer_enable) begin
                timer_count <= timer_count + 1;
                if (timer_expired) begin
                    if (timer_irq_enable)
                        irq <= 1'b1;
                    if (timer_auto_reload)
                        timer_count <= timer_reload_val;
                    else
                        timer_enable <= 1'b0;
                end
            end
        end
    end

    always @(*) begin
        rdata = 32'd0;
        if (re) begin
            rdata = timer_count;
        end
    end

    always @(posedge clk) begin
        if (we) begin
            case (wdata[31:28])
                4'h0: timer_count   <= wdata[27:0];
                4'h1: timer_compare <= wdata;
                4'h2: begin
                    timer_enable      <= wdata[0];
                    timer_irq_enable  <= wdata[1];
                    timer_auto_reload <= wdata[2];
                end
                4'h3: timer_reload_val <= wdata;
                default: ;
            endcase
        end
    end

endmodule
