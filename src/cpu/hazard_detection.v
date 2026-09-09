module hazard_detection (
    input  wire [4:0] id_ex_rd,
    input  wire       id_ex_mem_read,
    input  wire [4:0] if_id_rs1,
    input  wire [4:0] if_id_rs2,
    input  wire       id_ex_reg_we,
    output wire       stall
);

    assign stall = (id_ex_mem_read && id_ex_reg_we &&
                   (id_ex_rd != 5'd0) &&
                   ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)));

endmodule
