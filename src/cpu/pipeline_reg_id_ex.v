module pipeline_reg_id_ex (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,
    input  wire [31:0] pc_in,
    input  wire [31:0] rs1_data_in,
    input  wire [31:0] rs2_data_in,
    input  wire [31:0] imm_in,
    input  wire [4:0]  rd_addr_in,
    input  wire [4:0]  rs1_addr_in,
    input  wire [4:0]  rs2_addr_in,
    input  wire [3:0]  alu_op_in,
    input  wire        reg_we_in,
    input  wire        alu_src_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
    input  wire        branch_in,
    input  wire        jump_in,
    input  wire [2:0]  branch_type_in,
    output reg  [31:0] pc,
    output reg  [31:0] rs1_data,
    output reg  [31:0] rs2_data,
    output reg  [31:0] imm,
    output reg  [4:0]  rd_addr,
    output reg  [4:0]  rs1_addr,
    output reg  [4:0]  rs2_addr,
    output reg  [3:0]  alu_op,
    output reg         reg_we,
    output reg         alu_src,
    output reg         mem_read,
    output reg         mem_write,
    output reg         mem_to_reg,
    output reg         branch,
    output reg         jump,
    output reg  [2:0]  branch_type
);

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc          <= 32'd0;
            rs1_data    <= 32'd0;
            rs2_data    <= 32'd0;
            imm         <= 32'd0;
            rd_addr     <= 5'd0;
            rs1_addr    <= 5'd0;
            rs2_addr    <= 5'd0;
            alu_op      <= 4'd0;
            reg_we      <= 1'b0;
            alu_src     <= 1'b0;
            mem_read    <= 1'b0;
            mem_write   <= 1'b0;
            mem_to_reg  <= 1'b0;
            branch      <= 1'b0;
            jump        <= 1'b0;
            branch_type <= 3'd0;
        end else begin
            pc          <= pc_in;
            rs1_data    <= rs1_data_in;
            rs2_data    <= rs2_data_in;
            imm         <= imm_in;
            rd_addr     <= rd_addr_in;
            rs1_addr    <= rs1_addr_in;
            rs2_addr    <= rs2_addr_in;
            alu_op      <= alu_op_in;
            reg_we      <= reg_we_in;
            alu_src     <= alu_src_in;
            mem_read    <= mem_read_in;
            mem_write   <= mem_write_in;
            mem_to_reg  <= mem_to_reg_in;
            branch      <= branch_in;
            jump        <= jump_in;
            branch_type <= branch_type_in;
        end
    end

endmodule
