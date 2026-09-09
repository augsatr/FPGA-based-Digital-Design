module pipeline_reg_if_id (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,
    input  wire        flush,
    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in,
    output reg  [31:0] pc,
    output reg  [31:0] instr
);

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc    <= 32'd0;
            instr <= 32'd0;
        end else if (!stall) begin
            pc    <= pc_in;
            instr <= instr_in;
        end
    end

endmodule
