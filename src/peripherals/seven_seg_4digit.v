module seven_seg_4digit (
    input  wire        clk,
    input  wire [31:0] value,
    input  wire [3:0]  dots,
    output reg  [6:0]  seg,
    output reg  [3:0]  an,
    output wire        dp
);

    reg [1:0]  digit_sel = 0;
    reg [18:0] counter   = 0;
    reg [3:0]  digit;

    always @(posedge clk) begin
        counter <= counter + 1;
        if (counter == 0)
            digit_sel <= digit_sel + 1;
    end

    always @(*) begin
        case (digit_sel)
            2'b00: begin an = 4'b1110; digit = value[3:0];   end
            2'b01: begin an = 4'b1101; digit = value[7:4];   end
            2'b10: begin an = 4'b1011; digit = value[11:8];  end
            2'b11: begin an = 4'b0111; digit = value[15:12]; end
        endcase
    end

    assign dp = ~dots[digit_sel];

    always @(*) begin
        case (digit)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
        endcase
    end

endmodule
