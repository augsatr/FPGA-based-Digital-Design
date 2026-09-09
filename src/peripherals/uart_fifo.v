module uart_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
)(
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    wr_en,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    output wire                    wr_full,
    input  wire                    rd_en,
    output wire [DATA_WIDTH-1:0]  rd_data,
    output wire                    rd_empty,
    output wire [$clog2(DEPTH):0] count
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr;
    reg [$clog2(DEPTH):0] rd_ptr;

    assign count    = wr_ptr - rd_ptr;
    assign wr_full  = (count == DEPTH);
    assign rd_empty = (rd_ptr == wr_ptr);

    assign rd_data = mem[rd_ptr[$clog2(DEPTH)-1:0]];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (wr_en && !wr_full) begin
                mem[wr_ptr[$clog2(DEPTH)-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1;
            end
            if (rd_en && !rd_empty) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

endmodule
