module interrupt_controller (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  irq_sources,
    input  wire [31:0] wdata,
    input  wire        we,
    input  wire        re,
    output reg  [31:0] rdata,
    output wire        irq_out,
    input  wire        irq_ack
);

    reg [7:0]  irq_enable;
    reg [7:0]  irq_pending;
    reg [7:0]  irq_clear;
    reg [2:0]  irq_priority [0:7];
    reg [2:0]  active_priority;
    reg        irq_active;

    wire [7:0] pending_set = irq_sources & irq_enable;
    wire [7:0] pending_cleared = irq_pending & ~irq_clear;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            irq_enable <= 8'd0;
            irq_pending <= 8'd0;
            irq_clear <= 8'd0;
            irq_active <= 1'b0;
            active_priority <= 3'd0;
        end else begin
            irq_clear <= 8'd0;

            irq_pending <= (irq_pending | pending_set) & ~irq_clear;

            if (!irq_active && (irq_pending != 8'd0)) begin
                irq_active <= 1'b1;
                if (irq_pending[0]) active_priority <= 3'd0;
                else if (irq_pending[1]) active_priority <= 3'd1;
                else if (irq_pending[2]) active_priority <= 3'd2;
                else if (irq_pending[3]) active_priority <= 3'd3;
                else if (irq_pending[4]) active_priority <= 3'd4;
                else if (irq_pending[5]) active_priority <= 3'd5;
                else if (irq_pending[6]) active_priority <= 3'd6;
                else active_priority <= 3'd7;
            end

            if (irq_ack) begin
                irq_pending[active_priority] <= 1'b0;
                irq_clear[active_priority] <= 1'b1;
                irq_active <= 1'b0;
            end
        end
    end

    assign irq_out = irq_active;

    always @(*) begin
        rdata = 32'd0;
        if (re) begin
            rdata[7:0]   = irq_pending;
            rdata[15:8]  = irq_enable;
            rdata[23:16] = irq_sources;
            rdata[24]    = irq_active;
            rdata[27:25] = active_priority;
        end
    end

    always @(posedge clk) begin
        if (we) begin
            irq_enable <= wdata[15:8];
        end
    end

endmodule
