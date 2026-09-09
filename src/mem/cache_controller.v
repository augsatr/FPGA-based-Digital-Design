module cache_controller #(
    parameter CACHE_LINES = 256,
    parameter BLOCK_WORDS = 4,
    parameter ADDR_WIDTH  = 32
)(
    input  wire        clk,
    input  wire        rst,
    // CPU interface
    input  wire [ADDR_WIDTH-1:0] cpu_addr,
    input  wire [31:0] cpu_wdata,
    output reg  [31:0] cpu_rdata,
    input  wire        cpu_we,
    input  wire        cpu_re,
    input  wire [3:0]  cpu_be,
    output reg         cpu_ready,
    // Memory interface
    output reg  [ADDR_WIDTH-1:0] mem_addr,
    output reg  [31:0] mem_wdata,
    input  wire [31:0] mem_rdata,
    output reg         mem_we,
    output reg         mem_re,
    output reg  [3:0]  mem_be
);

    localparam OFFSET_BITS = $clog2(BLOCK_WORDS * 4);
    localparam INDEX_BITS  = $clog2(CACHE_LINES);
    localparam TAG_BITS    = ADDR_WIDTH - OFFSET_BITS - INDEX_BITS;

    localparam IDLE      = 3'b000;
    localparam CHECK     = 3'b001;
    localparam MISS_FILL = 3'b010;
    localparam WRITEBACK = 3'b011;
    localparam DONE      = 3'b100;

    reg [2:0] state;

    reg [TAG_BITS-1:0]  tag_array   [0:CACHE_LINES-1];
    reg                 valid_array [0:CACHE_LINES-1];
    reg                 dirty_array [0:CACHE_LINES-1];
    reg [31:0]          data_array  [0:CACHE_LINES*BLOCK_WORDS-1];

    wire [OFFSET_BITS-1:0] offset = cpu_addr[OFFSET_BITS-1:0];
    wire [INDEX_BITS-1:0]  index  = cpu_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    wire [TAG_BITS-1:0]    tag    = cpu_addr[ADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];

    wire hit = valid_array[index] && (tag_array[index] == tag);

    reg [3:0] fill_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            cpu_ready <= 1'b0;
            cpu_rdata <= 32'd0;
            mem_addr  <= 32'd0;
            mem_wdata <= 32'd0;
            mem_we    <= 1'b0;
            mem_re    <= 1'b0;
            mem_be    <= 4'b0000;
            fill_count <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    cpu_ready <= 1'b0;
                    if (cpu_re || cpu_we)
                        state <= CHECK;
                end

                CHECK: begin
                    if (hit) begin
                        if (cpu_we) begin
                            data_array[{index, offset[OFFSET_BITS-1:2]}] <= cpu_wdata;
                            dirty_array[index] <= 1'b1;
                        end else begin
                            cpu_rdata <= data_array[{index, offset[OFFSET_BITS-1:2]}];
                        end
                        cpu_ready <= 1'b1;
                        state     <= DONE;
                    end else begin
                        if (dirty_array[index])
                            state <= WRITEBACK;
                        else
                            state <= MISS_FILL;
                        fill_count <= 4'd0;
                    end
                end

                WRITEBACK: begin
                    mem_addr  <= {tag_array[index], index, {OFFSET_BITS{1'b0}}};
                    mem_wdata <= data_array[{index, fill_count[1:0]}];
                    mem_we    <= 1'b1;
                    mem_be    <= 4'b1111;
                    if (fill_count == BLOCK_WORDS - 1) begin
                        dirty_array[index] <= 1'b0;
                        state <= MISS_FILL;
                        fill_count <= 4'd0;
                    end else begin
                        fill_count <= fill_count + 1;
                    end
                end

                MISS_FILL: begin
                    mem_addr <= {cpu_addr[ADDR_WIDTH-1:OFFSET_BITS], fill_count[1:0], 2'b00};
                    mem_re   <= 1'b1;
                    mem_be   <= 4'b1111;
                    if (fill_count == BLOCK_WORDS - 1) begin
                        tag_array[index]   <= tag;
                        valid_array[index] <= 1'b1;
                        state <= CHECK;
                    end else begin
                        fill_count <= fill_count + 1;
                    end
                end

                DONE: begin
                    cpu_ready <= 1'b0;
                    mem_we    <= 1'b0;
                    mem_re    <= 1'b0;
                    state     <= IDLE;
                end
            endcase
        end
    end

endmodule
