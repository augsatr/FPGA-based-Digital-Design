module control_unit_32 (
    input  wire [31:0] instruction,
    output wire [4:0]  rs1_addr,
    output wire [4:0]  rs2_addr,
    output wire [4:0]  rd_addr,
    output reg  [31:0] imm,
    output reg  [3:0]  alu_op,
    output reg         alu_src,
    output reg         reg_we,
    output reg         mem_read,
    output reg         mem_write,
    output reg         mem_to_reg,
    output reg         branch,
    output reg         jump,
    output reg  [2:0]  branch_type,
    output reg  [1:0]  imm_type
);

    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];

    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign rd_addr  = instruction[11:7];

    localparam OPC_R    = 7'b0110011;
    localparam OPC_I    = 7'b0010011;
    localparam OPC_LOAD = 7'b0000011;
    localparam OPC_S    = 7'b0100011;
    localparam OPC_B    = 7'b1100011;
    localparam OPC_LUI  = 7'b0110111;
    localparam OPC_AUIPC= 7'b0010111;
    localparam OPC_JAL  = 7'b1101111;
    localparam OPC_JALR = 7'b1100111;
    localparam OPC_SYS  = 7'b1110011;

    localparam F3_ADD = 3'b000;
    localparam F3_SLL = 3'b001;
    localparam F3_SLT = 3'b010;
    localparam F3_XOR = 3'b100;
    localparam F3_SRL = 3'b101;
    localparam F3_OR  = 3'b110;
    localparam F3_AND = 3'b111;

    always @(*) begin
        alu_op     = 4'b0000;
        alu_src    = 1'b0;
        reg_we     = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        branch_type = 3'b000;
        imm        = 32'd0;
        imm_type   = 2'b00;

        case (opcode)
            OPC_R: begin
                reg_we = 1'b1;
                case (funct3)
                    F3_ADD: alu_op = (funct7[5]) ? 4'b0001 : 4'b0000;
                    F3_SLL: alu_op = 4'b0110;
                    F3_SLT: alu_op = 4'b1001;
                    F3_XOR: alu_op = 4'b0100;
                    F3_SRL: alu_op = (funct7[5]) ? 4'b1000 : 4'b0111;
                    F3_OR:  alu_op = 4'b0011;
                    F3_AND: alu_op = 4'b0010;
                    default: alu_op = 4'b0000;
                endcase
            end

            OPC_I: begin
                reg_we  = 1'b1;
                alu_src = 1'b1;
                imm     = {{20{instruction[31]}}, instruction[31:20]};
                imm_type = 2'b00;
                case (funct3)
                    F3_ADD: alu_op = 4'b0000;
                    F3_SLL: alu_op = 4'b0110;
                    F3_SLT: alu_op = 4'b1001;
                    F3_XOR: alu_op = 4'b0100;
                    F3_SRL: alu_op = (funct7[5]) ? 4'b1000 : 4'b0111;
                    F3_OR:  alu_op = 4'b0011;
                    F3_AND: alu_op = 4'b0010;
                    default: alu_op = 4'b0000;
                endcase
            end

            OPC_LOAD: begin
                reg_we    = 1'b1;
                alu_src   = 1'b1;
                mem_read  = 1'b1;
                mem_to_reg = 1'b1;
                alu_op    = 4'b0000;
                imm       = {{20{instruction[31]}}, instruction[31:20]};
                imm_type  = 2'b00;
            end

            OPC_S: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 4'b0000;
                imm       = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
                imm_type  = 2'b01;
            end

            OPC_B: begin
                branch = 1'b1;
                alu_op = 4'b0001;
                imm    = {{19{instruction[31]}}, instruction[31], instruction[7],
                          instruction[30:25], instruction[11:8], 1'b0};
                imm_type = 2'b10;
                case (funct3)
                    3'b000: branch_type = 3'b000; // BEQ
                    3'b001: branch_type = 3'b001; // BNE
                    3'b100: branch_type = 3'b100; // BLT
                    3'b101: branch_type = 3'b101; // BGE
                    3'b110: branch_type = 3'b110; // BLTU
                    3'b111: branch_type = 3'b111; // BGEU
                    default: branch_type = 3'b000;
                endcase
            end

            OPC_JAL: begin
                jump   = 1'b1;
                reg_we = 1'b1;
                imm    = {{11{instruction[31]}}, instruction[31], instruction[19:12],
                          instruction[20], instruction[30:21], 1'b0};
                imm_type = 2'b11;
            end

            OPC_JALR: begin
                jump    = 1'b1;
                reg_we  = 1'b1;
                alu_src = 1'b1;
                alu_op  = 4'b0000;
                imm     = {{20{instruction[31]}}, instruction[31:20]};
                imm_type = 2'b00;
            end

            OPC_LUI: begin
                reg_we = 1'b1;
                imm    = {instruction[31:12], 12'd0};
                alu_op = 4'b0000;
                alu_src = 1'b1;
            end

            OPC_AUIPC: begin
                reg_we  = 1'b1;
                imm     = {instruction[31:12], 12'd0};
                alu_op  = 4'b0000;
                alu_src = 1'b1;
            end

            default: begin
                alu_op  = 4'b1111;
                reg_we  = 1'b0;
            end
        endcase
    end

endmodule
