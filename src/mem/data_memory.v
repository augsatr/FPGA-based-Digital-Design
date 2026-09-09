module data_memory #(
    parameter MEM_SIZE = 1024
)(
    input  wire        clk,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata,
    input  wire        we,
    input  wire        re,
    input  wire [3:0]  be
);

    reg [31:0] mem [0:MEM_SIZE-1];

    wire [29:0] word_addr = addr[31:2];

    assign rdata = (re) ? mem[word_addr] : 32'd0;

    always @(posedge clk) begin
        if (we) begin
            if (be[0]) mem[word_addr][7:0]   <= wdata[7:0];
            if (be[1]) mem[word_addr][15:8]  <= wdata[15:8];
            if (be[2]) mem[word_addr][23:16] <= wdata[23:16];
            if (be[3]) mem[word_addr][31:24] <= wdata[31:24];
        end
    end

    integer i;
    initial begin
        for (i = 0; i < MEM_SIZE; i = i + 1)
            mem[i] = 32'd0;
    end

endmodule
