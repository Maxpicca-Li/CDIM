`timescale 1ns/1ps
module mul(
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    input sign,
    input start,
    output [63:0] result,
    output reg ready
);

wire a_sign = a[31];
wire b_sign = b[31];
wire out_sign = a_sign ^ b_sign;

wire [31:0] a_abs = a_sign ? -a : a;
wire [31:0] b_abs = b_sign ? -b : b;

wire [31:0] cal_a = sign ? a_abs : a;
wire [31:0] cal_b = sign ? b_abs : b;

reg [31:0] part_0;
reg [31:0] part_1;
reg [31:0] part_2;
reg [31:0] part_3;

always_ff @(posedge clk) begin
    if (rst) begin
        ready <= 0;
        part_0 <= 0;
        part_1 <= 0;
        part_2 <= 0;
        part_3 <= 0;
    end
    else begin
        if (!ready) begin
            if (start) begin
                part_0 <= cal_a[15:0 ] * cal_b[15:0 ];
                part_1 <= cal_a[15:0 ] * cal_b[31:16];
                part_2 <= cal_a[31:16] * cal_b[15:0 ];
                part_3 <= cal_a[31:16] * cal_b[31:16];
                ready <= 1'b1;
            end
        end
        else ready <= 1'b0;
    end
end

wire [63:0] mid_result = {32'd0,part_0} + {16'd0,part_1,16'd0} + {16'd0,part_2,16'd0} + {part_3,32'd0};

assign result = sign && out_sign ? -mid_result : mid_result;

endmodule