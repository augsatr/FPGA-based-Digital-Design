module cpu_pipeline (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_data,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    input  wire [31:0] dmem_rdata,
    output wire        dmem_we,
    output wire        dmem_re,
    output wire [3:0]  dmem_be,
    input  wire        irq,
    output wire        irq_ack
);

    // IF stage
    reg  [31:0] pc;
    wire [31:0] pc_next;
    wire [31:0] pc_plus4 = pc + 32'd4;
    wire [31:0] pc_branch;
    wire        branch_taken;
    wire        stall;

    // IF/ID pipeline register
    wire [31:0] if_id_pc;
    wire [31:0] if_id_instr;

    // ID stage signals
    wire [4:0]  id_rs1_addr, id_rs2_addr, id_rd_addr;
    wire [31:0] id_imm;
    wire [3:0]  id_alu_op;
    wire        id_alu_src, id_reg_we, id_mem_read, id_mem_write;
    wire        id_mem_to_reg, id_branch, id_jump;
    wire [2:0]  id_branch_type;
    wire [1:0]  id_imm_type;
    wire [31:0] id_rs1_data, id_rs2_data;

    // ID/EX pipeline register
    wire [31:0] id_ex_pc, id_ex_rs1_data, id_ex_rs2_data, id_ex_imm;
    wire [4:0]  id_ex_rd_addr, id_ex_rs1_addr, id_ex_rs2_addr;
    wire [3:0]  id_ex_alu_op;
    wire        id_ex_reg_we, id_ex_alu_src, id_ex_mem_read, id_ex_mem_write;
    wire        id_ex_mem_to_reg, id_ex_branch, id_ex_jump;
    wire [2:0]  id_ex_branch_type;

    // EX stage signals
    wire [31:0] ex_rs1_fwd, ex_rs2_fwd;
    wire [31:0] ex_alu_a, ex_alu_b, ex_alu_result;
    wire        ex_zero, ex_negative;
    wire [1:0]  forward_a, forward_b;

    // Branch comparison
    wire        ex_branch_cond;
    wire [31:0] ex_branch_target = id_ex_pc + id_ex_imm;

    // EX/MEM pipeline register
    wire [31:0] ex_mem_alu_result, ex_mem_rs2_data;
    wire [4:0]  ex_mem_rd_addr;
    wire        ex_mem_reg_we, ex_mem_mem_read, ex_mem_mem_write;
    wire        ex_mem_mem_to_reg, ex_mem_branch, ex_mem_branch_taken;
    wire [31:0] ex_mem_branch_target;

    // MEM stage signals
    wire [31:0] mem_read_data;

    // MEM/WB pipeline register
    wire [31:0] mem_wb_alu_result, mem_wb_mem_data;
    wire [4:0]  mem_wb_rd_addr;
    wire        mem_wb_reg_we, mem_wb_mem_to_reg;

    // WB stage signal
    wire [31:0] wb_data;

    assign imem_addr = pc;
    assign irq_ack   = 1'b0;

    // Next PC logic
    assign pc_next = (ex_mem_branch_taken) ? ex_mem_branch_target :
                     (id_ex_jump) ? (id_ex_pc + id_ex_imm) : pc_plus4;

    assign branch_taken = ex_mem_branch_taken;

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'h00000000;
        else if (!stall)
            pc <= pc_next;
    end

    // Hazard detection
    hazard_detection u_hazard (
        .id_ex_rd      (id_ex_rd_addr),
        .id_ex_mem_read(id_ex_mem_read),
        .if_id_rs1     (id_rs1_addr),
        .if_id_rs2     (id_rs2_addr),
        .id_ex_reg_we  (id_ex_reg_we),
        .stall         (stall)
    );

    // Forwarding unit
    forwarding_unit u_forward (
        .ex_mem_rd      (ex_mem_rd_addr),
        .ex_mem_reg_we  (ex_mem_reg_we),
        .mem_wb_rd      (mem_wb_rd_addr),
        .mem_wb_reg_we  (mem_wb_reg_we),
        .id_ex_rs1      (id_ex_rs1_addr),
        .id_ex_rs2      (id_ex_rs2_addr),
        .forward_a      (forward_a),
        .forward_b      (forward_b)
    );

    // Forwarding muxes
    assign ex_rs1_fwd = (forward_a == 2'b10) ? ex_mem_alu_result :
                        (forward_a == 2'b01) ? wb_data : id_ex_rs1_data;
    assign ex_rs2_fwd = (forward_b == 2'b10) ? ex_mem_alu_result :
                        (forward_b == 2'b01) ? wb_data : id_ex_rs2_data;

    // Branch condition evaluation
    reg ex_branch_cond_r;
    always @(*) begin
        case (id_ex_branch_type)
            3'b000: ex_branch_cond_r = (ex_rs1_fwd == ex_rs2_fwd);           // BEQ
            3'b001: ex_branch_cond_r = (ex_rs1_fwd != ex_rs2_fwd);           // BNE
            3'b100: ex_branch_cond_r = ($signed(ex_rs1_fwd) < $signed(ex_rs2_fwd)); // BLT
            3'b101: ex_branch_cond_r = ($signed(ex_rs1_fwd) >= $signed(ex_rs2_fwd)); // BGE
            3'b110: ex_branch_cond_r = (ex_rs1_fwd < ex_rs2_fwd);            // BLTU
            3'b111: ex_branch_cond_r = (ex_rs1_fwd >= ex_rs2_fwd);           // BGEU
            default: ex_branch_cond_r = 1'b0;
        endcase
    end
    assign ex_branch_cond = ex_branch_cond_r;

    // Pipeline registers
    pipeline_reg_if_id u_if_id (
        .clk     (clk),
        .rst     (rst),
        .stall   (stall),
        .flush   (branch_taken),
        .pc_in   (pc),
        .instr_in(imem_data),
        .pc      (if_id_pc),
        .instr   (if_id_instr)
    );

    control_unit_32 u_cu (
        .instruction(if_id_instr),
        .rs1_addr   (id_rs1_addr),
        .rs2_addr   (id_rs2_addr),
        .rd_addr    (id_rd_addr),
        .imm        (id_imm),
        .alu_op     (id_alu_op),
        .alu_src    (id_alu_src),
        .reg_we     (id_reg_we),
        .mem_read   (id_mem_read),
        .mem_write  (id_mem_write),
        .mem_to_reg (id_mem_to_reg),
        .branch     (id_branch),
        .jump       (id_jump),
        .branch_type(id_branch_type),
        .imm_type   (id_imm_type)
    );

    register_file_32 u_rf (
        .clk      (clk),
        .rst      (rst),
        .rd_addr  (mem_wb_rd_addr),
        .rd_data  (wb_data),
        .rd_we    (mem_wb_reg_we),
        .rs1_addr (id_rs1_addr),
        .rs1_data (id_rs1_data),
        .rs2_addr (id_rs2_addr),
        .rs2_data (id_rs2_data)
    );

    pipeline_reg_id_ex u_id_ex (
        .clk          (clk),
        .rst          (rst),
        .flush        (branch_taken || stall),
        .pc_in        (if_id_pc),
        .rs1_data_in  (id_rs1_data),
        .rs2_data_in  (id_rs2_data),
        .imm_in       (id_imm),
        .rd_addr_in   (id_rd_addr),
        .rs1_addr_in  (id_rs1_addr),
        .rs2_addr_in  (id_rs2_addr),
        .alu_op_in    (id_alu_op),
        .reg_we_in    (id_reg_we),
        .alu_src_in   (id_alu_src),
        .mem_read_in  (id_mem_read),
        .mem_write_in (id_mem_write),
        .mem_to_reg_in(id_mem_to_reg),
        .branch_in    (id_branch),
        .jump_in      (id_jump),
        .branch_type_in(id_branch_type),
        .pc           (id_ex_pc),
        .rs1_data     (id_ex_rs1_data),
        .rs2_data     (id_ex_rs2_data),
        .imm          (id_ex_imm),
        .rd_addr      (id_ex_rd_addr),
        .rs1_addr     (id_ex_rs1_addr),
        .rs2_addr     (id_ex_rs2_addr),
        .alu_op       (id_ex_alu_op),
        .reg_we       (id_ex_reg_we),
        .alu_src      (id_ex_alu_src),
        .mem_read     (id_ex_mem_read),
        .mem_write    (id_ex_mem_write),
        .mem_to_reg   (id_ex_mem_to_reg),
        .branch       (id_ex_branch),
        .jump         (id_ex_jump),
        .branch_type  (id_ex_branch_type)
    );

    assign ex_alu_a = ex_rs1_fwd;
    assign ex_alu_b = id_ex_alu_src ? id_ex_imm : ex_rs2_fwd;

    alu_32 u_alu (
        .a       (ex_alu_a),
        .b       (ex_alu_b),
        .alu_op  (id_ex_alu_op),
        .result  (ex_alu_result),
        .zero    (ex_zero),
        .negative(ex_negative)
    );

    wire ex_branch_taken_w = id_ex_branch && ex_branch_cond;

    pipeline_reg_ex_mem u_ex_mem (
        .clk             (clk),
        .rst             (rst),
        .alu_result_in   (ex_alu_result),
        .rs2_data_in     (ex_rs2_fwd),
        .rd_addr_in      (id_ex_rd_addr),
        .reg_we_in       (id_ex_reg_we),
        .mem_read_in     (id_ex_mem_read),
        .mem_write_in    (id_ex_mem_write),
        .mem_to_reg_in   (id_ex_mem_to_reg),
        .branch_in       (id_ex_branch),
        .branch_taken_in (ex_branch_taken_w),
        .branch_target_in(ex_branch_target),
        .alu_result      (ex_mem_alu_result),
        .rs2_data        (ex_mem_rs2_data),
        .rd_addr         (ex_mem_rd_addr),
        .reg_we          (ex_mem_reg_we),
        .mem_read        (ex_mem_mem_read),
        .mem_write       (ex_mem_mem_write),
        .mem_to_reg      (ex_mem_mem_to_reg),
        .branch          (/* unused */),
        .branch_taken    (ex_mem_branch_taken),
        .branch_target   (ex_mem_branch_target)
    );

    assign dmem_addr  = ex_mem_alu_result;
    assign dmem_wdata = ex_mem_rs2_data;
    assign dmem_we    = ex_mem_mem_write;
    assign dmem_re    = ex_mem_mem_read;
    assign dmem_be    = 4'b1111;

    pipeline_reg_mem_wb u_mem_wb (
        .clk          (clk),
        .rst          (rst),
        .alu_result_in(ex_mem_alu_result),
        .mem_data_in  (dmem_rdata),
        .rd_addr_in   (ex_mem_rd_addr),
        .reg_we_in    (ex_mem_reg_we),
        .mem_to_reg_in(ex_mem_mem_to_reg),
        .alu_result   (mem_wb_alu_result),
        .mem_data     (mem_wb_mem_data),
        .rd_addr      (mem_wb_rd_addr),
        .reg_we       (mem_wb_reg_we),
        .mem_to_reg   (mem_wb_mem_to_reg)
    );

    assign wb_data = mem_wb_mem_to_reg ? mem_wb_mem_data : mem_wb_alu_result;

endmodule
