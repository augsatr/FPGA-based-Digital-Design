module pipeline_reg_ex_mem (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] rs2_data_in,
    input  wire [4:0]  rd_addr_in,
    input  wire        reg_we_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
    input  wire        branch_in,
    input  wire        branch_taken_in,
    input  wire [31:0] branch_target_in,
    output reg  [31:0] alu_result,
    output reg  [31:0] rs2_data,
    output reg  [4:0]  rd_addr,
    output reg         reg_we,
    output reg         mem_read,
    output reg         mem_write,
    output reg         mem_to_reg,
    output reg         branch,
    output reg         branch_taken,
    output reg  [31:0] branch_target
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result    <= 32'd0;
            rs2_data      <= 32'd0;
            rd_addr       <= 5'd0;
            reg_we        <= 1'b0;
            mem_read      <= 1'b0;
            mem_write     <= 1'b0;
            mem_to_reg    <= 1'b0;
            branch        <= 1'b0;
            branch_taken  <= 1'b0;
            branch_target <= 32'd0;
        end else begin
            alu_result    <= alu_result_in;
            rs2_data      <= rs2_data_in;
            rd_addr       <= rd_addr_in;
            reg_we        <= reg_we_in;
            mem_read      <= mem_read_in;
            mem_write     <= mem_write_in;
            mem_to_reg    <= mem_to_reg_in;
            branch        <= branch_in;
            branch_taken  <= branch_taken_in;
            branch_target <= branch_target_in;
        end
    end

endmodule
