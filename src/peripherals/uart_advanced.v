module uart_advanced #(
    parameter CLK_FREQ  = 100_000_000,
    parameter FIFO_DEPTH = 16
)(
    input  wire        clk,
    input  wire        rst,
    // UART lines
    input  wire        rx,
    output wire        tx,
    // CPU interface
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire        we,
    input  wire        re,
    output wire        tx_busy,
    output wire        rx_ready,
    // Flow control
    output wire        rts,
    input  wire        cts,
    // Status
    output wire [7:0]  status
);

    localparam CLKS_PER_BIT_9600  = CLK_FREQ / 9600;
    localparam CLKS_PER_BIT_19200 = CLK_FREQ / 19200;
    localparam CLKS_PER_BIT_38400 = CLK_FREQ / 38400;
    localparam CLKS_PER_BIT_57600 = CLK_FREQ / 57600;
    localparam CLKS_PER_BIT_115200 = CLK_FREQ / 115200;

    reg [2:0] baud_select;
    reg [12:0] clks_per_bit;

    always @(*) begin
        case (baud_select)
            3'd0: clks_per_bit = CLKS_PER_BIT_9600;
            3'd1: clks_per_bit = CLKS_PER_BIT_19200;
            3'd2: clks_per_bit = CLKS_PER_BIT_38400;
            3'd3: clks_per_bit = CLKS_PER_BIT_57600;
            3'd4: clks_per_bit = CLKS_PER_BIT_115200;
            default: clks_per_bit = CLKS_PER_BIT_9600;
        endcase
    end

    // Registers
    // 0x00: TX Data (write)
    // 0x04: RX Data (read)
    // 0x08: Status (read)
    // 0x0C: Control (write)
    // 0x10: Baud rate select (write)

    wire [7:0] tx_fifo_data;
    wire       tx_fifo_empty;
    wire       tx_fifo_full;
    wire [3:0] tx_fifo_count;

    wire [7:0] rx_fifo_data;
    wire       rx_fifo_full;
    wire       rx_fifo_empty;
    wire [3:0] rx_fifo_count;

    reg        tx_start;
    reg        tx_start_d;
    wire       tx_line_busy;

    wire [7:0] rx_byte;
    wire       rx_valid;
    wire [7:0] rx_status;

    wire tx_can_send = cts;

    assign rts = !rx_fifo_full;
    assign tx_busy = tx_fifo_full || tx_line_busy;
    assign rx_ready = !rx_fifo_empty;
    assign status = {rx_fifo_full, rx_fifo_empty, tx_fifo_full, tx_fifo_empty,
                     tx_line_busy, 2'b00, rx_valid};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            baud_select <= 3'd0;
            tx_start    <= 1'b0;
            tx_start_d  <= 1'b0;
        end else begin
            tx_start_d <= tx_start;
            if (we) begin
                case (addr[3:0])
                    4'h0: begin
                        // TX data write triggers FIFO push
                    end
                    4'hC: begin
                        baud_select <= wdata[2:0];
                    end
                    default: ;
                endcase
            end
        end
    end

    // Register writes
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_start <= 1'b0;
        end else begin
            if (we && addr[3:0] == 4'h0) begin
                tx_start <= 1'b1;
            end else if (tx_start_d) begin
                tx_start <= 1'b0;
            end
        end
    end

    always @(*) begin
        rdata = 32'd0;
        if (re) begin
            case (addr[3:0])
                4'h0: rdata = {24'd0, rx_fifo_data};
                4'h4: rdata = {24'd0, rx_status};
                4'h8: rdata = {24'd0, status};
                default: rdata = 32'd0;
            endcase
        end
    end

    // TX FIFO
    uart_fifo #(.DATA_WIDTH(8), .DEPTH(FIFO_DEPTH)) u_tx_fifo (
        .clk      (clk),
        .rst      (rst),
        .wr_en    (we && addr[3:0] == 4'h0),
        .wr_data  (wdata[7:0]),
        .wr_full  (tx_fifo_full),
        .rd_en    (!tx_fifo_empty && !tx_line_busy && tx_can_send),
        .rd_data  (tx_fifo_data),
        .rd_empty (tx_fifo_empty),
        .count    (tx_fifo_count)
    );

    // RX FIFO
    uart_fifo #(.DATA_WIDTH(8), .DEPTH(FIFO_DEPTH)) u_rx_fifo (
        .clk      (clk),
        .rst      (rst),
        .wr_en    (rx_valid),
        .wr_data  (rx_byte),
        .wr_full  (rx_fifo_full),
        .rd_en    (re && addr[3:0] == 4'h0),
        .rd_data  (rx_fifo_data),
        .rd_empty (rx_fifo_empty),
        .count    (rx_fifo_count)
    );

    // TX Engine
    localparam TX_IDLE  = 3'b000;
    localparam TX_START = 3'b001;
    localparam TX_DATA  = 3'b010;
    localparam TX_STOP  = 3'b011;

    reg [2:0]  tx_state;
    reg [12:0] tx_clk_count;
    reg [2:0]  tx_bit_index;
    reg [7:0]  tx_shift;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_state     <= TX_IDLE;
            tx_clk_count <= 0;
            tx_bit_index <= 0;
            tx_shift     <= 0;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    if (!tx_fifo_empty && tx_can_send && !tx_line_busy) begin
                        tx_state     <= TX_START;
                        tx_shift     <= tx_fifo_data;
                        tx_clk_count <= 0;
                    end
                end
                TX_START: begin
                    if (tx_clk_count == clks_per_bit - 1) begin
                        tx_clk_count <= 0;
                        tx_state     <= TX_DATA;
                        tx_bit_index <= 0;
                    end else begin
                        tx_clk_count <= tx_clk_count + 1;
                    end
                end
                TX_DATA: begin
                    if (tx_clk_count == clks_per_bit - 1) begin
                        tx_clk_count <= 0;
                        if (tx_bit_index == 7)
                            tx_state <= TX_STOP;
                        else
                            tx_bit_index <= tx_bit_index + 1;
                    end else begin
                        tx_clk_count <= tx_clk_count + 1;
                    end
                end
                TX_STOP: begin
                    if (tx_clk_count == clks_per_bit - 1) begin
                        tx_state     <= TX_IDLE;
                        tx_clk_count <= 0;
                    end else begin
                        tx_clk_count <= tx_clk_count + 1;
                    end
                end
                default: tx_state <= TX_IDLE;
            endcase
        end
    end

    reg tx_line;
    assign tx = tx_line;
    assign tx_line_busy = (tx_state != TX_IDLE);

    always @(*) begin
        case (tx_state)
            TX_IDLE:  tx_line = 1'b1;
            TX_START: tx_line = 1'b0;
            TX_DATA:  tx_line = tx_shift[tx_bit_index];
            TX_STOP:  tx_line = 1'b1;
            default:  tx_line = 1'b1;
        endcase
    end

    // RX Engine
    localparam RX_IDLE  = 3'b000;
    localparam RX_START = 3'b001;
    localparam RX_DATA  = 3'b010;
    localparam RX_STOP  = 3'b011;

    reg [2:0]  rx_state;
    reg [12:0] rx_clk_count;
    reg [2:0]  rx_bit_index;
    reg [7:0]  rx_shift;
    reg        rx_d1, rx_d2;

    assign rx_status = {7'd0, rx_state != RX_IDLE};

    always @(posedge clk) begin
        rx_d1 <= rx;
        rx_d2 <= rx_d1;
    end

    wire rx_sample = rx_d2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_state     <= RX_IDLE;
            rx_clk_count <= 0;
            rx_bit_index <= 0;
            rx_shift     <= 0;
        end else begin
            case (rx_state)
                RX_IDLE: begin
                    if (rx_sample == 1'b0) begin
                        rx_state     <= RX_START;
                        rx_clk_count <= 0;
                    end
                end
                RX_START: begin
                    if (rx_clk_count == (clks_per_bit - 1) / 2) begin
                        if (rx_sample == 1'b0) begin
                            rx_clk_count <= 0;
                            rx_state     <= RX_DATA;
                        end else begin
                            rx_state <= RX_IDLE;
                        end
                    end else begin
                        rx_clk_count <= rx_clk_count + 1;
                    end
                end
                RX_DATA: begin
                    if (rx_clk_count == clks_per_bit - 1) begin
                        rx_clk_count          <= 0;
                        rx_shift[rx_bit_index] <= rx_sample;
                        if (rx_bit_index == 7)
                            rx_state <= RX_STOP;
                        else
                            rx_bit_index <= rx_bit_index + 1;
                    end else begin
                        rx_clk_count <= rx_clk_count + 1;
                    end
                end
                RX_STOP: begin
                    if (rx_clk_count == clks_per_bit - 1) begin
                        rx_state     <= RX_IDLE;
                        rx_clk_count <= 0;
                    end else begin
                        rx_clk_count <= rx_clk_count + 1;
                    end
                end
                default: rx_state <= RX_IDLE;
            endcase
        end
    end

    assign rx_byte  = rx_shift;
    assign rx_valid = (rx_state == RX_STOP) && (rx_clk_count == clks_per_bit - 1);

endmodule
