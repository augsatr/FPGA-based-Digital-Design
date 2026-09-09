module pipeline_reg_mem_wb (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] mem_data_in,
    input  wire [4:0]  rd_addr_in,
    input  wire        reg_we_in,
    input  wire        mem_to_reg_in,
    output reg  [31:0] alu_result,
    output reg  [31:0] mem_data,
    output reg  [4:0]  rd_addr,
    output reg         reg_we,
    output reg         mem_to_reg
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result <= 32'd0;
            mem_data   <= 32'd0;
            rd_addr    <= 5'd0;
            reg_we     <= 1'b0;
            mem_to_reg <= 1'b0;
        end else begin
            alu_result <= alu_result_in;
            mem_data   <= mem_data_in;
            rd_addr    <= rd_addr_in;
            reg_we     <= reg_we_in;
            mem_to_reg <= mem_to_reg_in;
        end
    end

endmodule
