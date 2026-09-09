module wishbone_bus (
    input  wire        clk,
    input  wire        rst,
    // Master (CPU)
    input  wire [31:0] m_addr,
    input  wire [31:0] m_wdata,
    output reg  [31:0] m_rdata,
    input  wire        m_we,
    input  wire        m_re,
    output wire        m_ready,
    // Slave 0: Instruction Memory (0x00000000 - 0x00000FFF)
    output reg  [31:0] s0_addr,
    output reg  [31:0] s0_wdata,
    input  wire [31:0] s0_rdata,
    output reg         s0_we,
    output reg         s0_re,
    output reg  [3:0]  s0_be,
    input  wire        s0_ready,
    // Slave 1: Data Memory (0x00001000 - 0x00001FFF)
    output reg  [31:0] s1_addr,
    output reg  [31:0] s1_wdata,
    input  wire [31:0] s1_rdata,
    output reg         s1_we,
    output reg         s1_re,
    output reg  [3:0]  s1_be,
    input  wire        s1_ready,
    // Slave 2: UART (0x00002000 - 0x00002007)
    output reg  [31:0] s2_addr,
    output reg  [31:0] s2_wdata,
    input  wire [31:0] s2_rdata,
    output reg         s2_we,
    output reg         s2_re,
    input  wire        s2_ready,
    // Slave 3: Timer (0x00003000 - 0x00003007)
    output reg  [31:0] s3_addr,
    output reg  [31:0] s3_wdata,
    input  wire [31:0] s3_rdata,
    output reg         s3_we,
    output reg         s3_re,
    input  wire        s3_ready,
    // Slave 4: GPIO (0x00004000 - 0x00004007)
    output reg  [31:0] s4_addr,
    output reg  [31:0] s4_wdata,
    input  wire [31:0] s4_rdata,
    output reg         s4_we,
    output reg         s4_re,
    input  wire        s4_ready,
    // Slave 5: Interrupt Controller (0x00005000 - 0x00005003)
    output reg  [31:0] s5_addr,
    output reg  [31:0] s5_wdata,
    input  wire [31:0] s5_rdata,
    output reg         s5_we,
    output reg         s5_re,
    input  wire        s5_ready
);

    localparam ADDR_IMEM   = 32'h00000000;
    localparam ADDR_DMEM   = 32'h00001000;
    localparam ADDR_UART   = 32'h00002000;
    localparam ADDR_TIMER  = 32'h00003000;
    localparam ADDR_GPIO   = 32'h00004000;
    localparam ADDR_INT    = 32'h00005000;

    localparam MASK_IMEM  = 32'hFFFFF000;
    localparam MASK_DMEM  = 32'hFFFFF000;
    localparam MASK_UART  = 32'hFFFFF000;
    localparam MASK_TIMER = 32'hFFFFF000;
    localparam MASK_GPIO  = 32'hFFFFF000;
    localparam MASK_INT   = 32'hFFFFF000;

    wire [3:0] sel;
    assign sel = (m_addr & MASK_IMEM)  == ADDR_IMEM  ? 4'd0 :
                 (m_addr & MASK_DMEM)  == ADDR_DMEM  ? 4'd1 :
                 (m_addr & MASK_UART)  == ADDR_UART  ? 4'd2 :
                 (m_addr & MASK_TIMER) == ADDR_TIMER ? 4'd3 :
                 (m_addr & MASK_GPIO)  == ADDR_GPIO  ? 4'd4 :
                 (m_addr & MASK_INT)   == ADDR_INT   ? 4'd5 : 4'hF;

    always @(*) begin
        s0_addr = 32'd0; s0_wdata = 32'd0; s0_we = 1'b0; s0_re = 1'b0; s0_be = 4'b0000;
        s1_addr = 32'd0; s1_wdata = 32'd0; s1_we = 1'b0; s1_re = 1'b0; s1_be = 4'b0000;
        s2_addr = 32'd0; s2_wdata = 32'd0; s2_we = 1'b0; s2_re = 1'b0;
        s3_addr = 32'd0; s3_wdata = 32'd0; s3_we = 1'b0; s3_re = 1'b0;
        s4_addr = 32'd0; s4_wdata = 32'd0; s4_we = 1'b0; s4_re = 1'b0;
        s5_addr = 32'd0; s5_wdata = 32'd0; s5_we = 1'b0; s5_re = 1'b0;
        m_rdata = 32'd0;

        case (sel)
            4'd0: begin
                s0_addr  = m_addr;
                s0_wdata = m_wdata;
                s0_we    = m_we;
                s0_re    = m_re;
                s0_be    = 4'b1111;
                m_rdata  = s0_rdata;
            end
            4'd1: begin
                s1_addr  = m_addr;
                s1_wdata = m_wdata;
                s1_we    = m_we;
                s1_re    = m_re;
                s1_be    = 4'b1111;
                m_rdata  = s1_rdata;
            end
            4'd2: begin
                s2_addr  = m_addr;
                s2_wdata = m_wdata;
                s2_we    = m_we;
                s2_re    = m_re;
                m_rdata  = s2_rdata;
            end
            4'd3: begin
                s3_addr  = m_addr;
                s3_wdata = m_wdata;
                s3_we    = m_we;
                s3_re    = m_re;
                m_rdata  = s3_rdata;
            end
            4'd4: begin
                s4_addr  = m_addr;
                s4_wdata = m_wdata;
                s4_we    = m_we;
                s4_re    = m_re;
                m_rdata  = s4_rdata;
            end
            4'd5: begin
                s5_addr  = m_addr;
                s5_wdata = m_wdata;
                s5_we    = m_we;
                s5_re    = m_re;
                m_rdata  = s5_rdata;
            end
            default: begin
                m_rdata = 32'd0;
            end
        endcase
    end

    wire [5:0] ready_onehot;
    assign ready_onehot[0] = (sel == 4'd0) ? s0_ready : 1'b1;
    assign ready_onehot[1] = (sel == 4'd1) ? s1_ready : 1'b1;
    assign ready_onehot[2] = (sel == 4'd2) ? s2_ready : 1'b1;
    assign ready_onehot[3] = (sel == 4'd3) ? s3_ready : 1'b1;
    assign ready_onehot[4] = (sel == 4'd4) ? s4_ready : 1'b1;
    assign ready_onehot[5] = (sel == 4'd5) ? s5_ready : 1'b1;

    assign m_ready = &ready_onehot;

endmodule
